#!/bin/bash
# File: backup_stack.sh
# Part of the sovereign-stack project.
# Version: 3.6.14 (Master Spec Compliant)
#
# Copyright (C) 2026 Henk van Hoek
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

# shellcheck disable=SC2154
set -u

# 1. Environment & Path Setup
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

# 2. Identity Guard (Sectie 2: Root Prevention)
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root."
    exit 1
fi

# 3. Sovereign Guard: Heavy Duty Locking (Sectie 2: Anti-Stacking)
exec 100>/tmp/sovereign_backup.lock
if ! flock -n 100; then
    exit 0
fi

# Internal Helpers
fatal_error() {
    local msg="$1"
    printf "%s: FATAL - %b\n" "$(date)" "$msg"
    if [ -n "${BACKUP_EMAIL:-}" ]; then
        local temp_err
        temp_err=$(mktemp)
        {
            echo "To: ${BACKUP_EMAIL}"
            echo "Subject: ❌ Sovereign Stack CRITICAL ERROR"
            echo "Content-Type: text/plain; charset=utf-8"
            echo ""
            printf "Critical Backup Failure:\n%b\n" "$msg"
        } > "$temp_err"
        msmtp "${BACKUP_EMAIL}" < "$temp_err"
        rm "$temp_err"
    fi
    exit 1
}

log_message() {
    echo "$(date): $1"
}

# 4. Environment & Path Guard (Sectie 2)
if [ -f "$ENV_PATH" ]; then
    set -a
    # shellcheck disable=SC1091,SC1090
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    fatal_error ".env file not found at $ENV_PATH"
fi

if ! ENV_CHECK_OUTPUT=$( "${SCRIPT_DIR}/verify_env.sh" 2>&1 ); then
    fatal_error "Environment verification failed. Missing or empty variables:\n\n$ENV_CHECK_OUTPUT"
fi

if [ ! -d "${DOCKER_ROOT:-}" ]; then
    fatal_error "DOCKER_ROOT directory [${DOCKER_ROOT:-}] does not exist."
fi

# Paths & Vars
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
BACKUP_DIR="${DOCKER_ROOT}/backups"
LOG_FILE="${BACKUP_DIR}/cron.log"
DB_EXPORT="${DOCKER_ROOT}/nextcloud/nextcloud_db_export.sql"

mkdir -p "$BACKUP_DIR"

# Logging setup - reached only after lock and guards
exec >> "$LOG_FILE" 2>&1

log_message "--- Backup Routine Started ---"

# 5. System Status (Sectie 3: Telemetry)
RAW_TEMP=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
TEMP_INT=${RAW_TEMP%.*}
TEMP_DISPLAY="${RAW_TEMP}'C"
DISK_USAGE=$(df -h "${DOCKER_ROOT}" | awk 'NR==2 {print $5}')

log_message "System Status: Temp=$TEMP_DISPLAY | Disk=$DISK_USAGE"

# 6. Database Export (Sectie 3: Database)
log_message "Exporting Nextcloud Database..."
if ! docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" \
    nextcloud > "$DB_EXPORT"; then
    log_message "WARNING: Database export failed."
fi

# 7. Build Dynamic Excludes (Sectie 3: Differentiation)
EXCLUDES=("--exclude=backups" "--exclude=.git" "--exclude=nextcloud/db" "--exclude=portainer/data")

if [ "${INCLUDE_FRIGATE_DATA:-false}" != "true" ]; then
    EXCLUDES+=("--exclude=storage")
    log_message "Mode: Excluding Frigate Videos (storage folder)"
fi

if [ "${INCLUDE_NEXTCLOUD_DATA:-false}" != "true" ]; then
    EXCLUDES+=("--exclude=nextcloud/data")
    log_message "Mode: Excluding Nextcloud User Files"
fi

# 8. Archive & Encrypt (Sectie 3: Security)
log_message "Archiving and Encrypting (sovereign_stack_${DATE})..."
sudo tar "${EXCLUDES[@]}" -czf - -C "$DOCKER_ROOT" . | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" \
    -out "${BACKUP_DIR}/${FILENAME}"

# 9. Remote Wake-up (Sectie 3: WOL Utility)
TARGET_REACHABLE=0
CLEAN_IP=$(echo "$BACKUP_TARGET_IP" | sed -e 's|^http://||' -e 's|^https://||')

if [ -n "${BACKUP_TARGET_MAC:-}" ] && [ -n "$CLEAN_IP" ]; then
    log_message "Attempting to wake backup target (${CLEAN_IP})..."
    if "${SCRIPT_DIR}/wake_target.sh" \
        "$BACKUP_TARGET_MAC" \
        "$CLEAN_IP" \
        "${BACKUP_MAX_RETRIES:-15}" \
        "${BACKUP_RETRY_WAIT:-6}"; then
        log_message "[OK] Target is online. Proceeding..."
        TARGET_REACHABLE=1
    else
        log_message "[ERROR] Target did not wake up within timeout."
    fi
fi

# 10. SFTP Transfer
SFTP_STATUS=1
if [ $TARGET_REACHABLE -eq 1 ]; then
    log_message "Transferring to ${BACKUP_TARGET_OS} Target..."
    BATCH_FILE=$(mktemp)
    echo "put ${BACKUP_DIR}/${FILENAME} ${BACKUP_TARGET_PATH}" > "$BATCH_FILE"
    echo "quit" >> "$BATCH_FILE"

    if sftp -b "$BATCH_FILE" "${BACKUP_TARGET_USER}@${CLEAN_IP}"; then
        SFTP_STATUS=0
    else
        SFTP_STATUS=1
    fi
    rm "$BATCH_FILE"
fi

# 11. Cleanup & Status Logic
log_message "Cleaning up local archives older than ${BACKUP_RETENTION_DAYS} day(s) specified in your .env file."
find "$BACKUP_DIR" -maxdepth 1 -name "sovereign_stack_*.enc" -mtime "+${BACKUP_RETENTION_DAYS}" -delete

PRIORITY="Normal"; PRIORITY_HEADER="3"
if [ $SFTP_STATUS -eq 0 ]; then
    STATUS_MSG="SUCCESS: Backup transferred to target."
    SUBJECT="✅ Sovereign Backup Success ($TEMP_DISPLAY)"
else
    STATUS_MSG="ERROR: Backup transfer FAILED."
    SUBJECT="❌ ALERT: Sovereign Backup FAILED"
    PRIORITY="High"; PRIORITY_HEADER="1"
fi

if [ "$TEMP_INT" -ge 80 ]; then
    SUBJECT="⚠️ CRITICAL TEMP: Sovereign Backup Alert ($TEMP_DISPLAY)"
    PRIORITY="High"; PRIORITY_HEADER="1"
fi

log_message "$STATUS_MSG"
log_message "--- Backup Routine Finished ---"

# 12. Email Report (Sectie 3: Reporting)
TEMP_MAIL=$(mktemp)
{
    echo "To: ${BACKUP_EMAIL}"
    echo "Subject: ${SUBJECT}"
    echo "X-Priority: ${PRIORITY_HEADER}"
    echo "Importance: ${PRIORITY}"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "Sovereign Health & Backup Report"
    echo "==============================="
    echo "Date:        $(date)"
    echo "Temperature: $TEMP_DISPLAY"
    echo "Disk Usage:  $DISK_USAGE"
    echo "Status:      ${STATUS_MSG}"
    echo "Filename:    ${FILENAME}"
    echo ""
    echo "REPORT LOG (LAST 50 LINES):"
    echo "------------------------------------------------------------"
    sed -n "/--- Backup Routine Started/,/--- Backup Routine Finished/p" "$LOG_FILE" | tail -n 50
    echo "------------------------------------------------------------"
    echo "End of Report."
} > "$TEMP_MAIL"

msmtp "${BACKUP_EMAIL}" < "$TEMP_MAIL"
rm "$TEMP_MAIL"
