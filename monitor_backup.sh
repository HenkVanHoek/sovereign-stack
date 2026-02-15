#!/bin/bash
# File: monitor_backup.sh
# Part of the sovereign-stack project.
# Version: 4.0.0 (Sovereign Awakening)#
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
# along with this program.  If not, see https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

# shellcheck disable=SC2154
set -u

# 1. Path Setup
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

# 2. Sovereign Guard: Heavy Duty Locking (Sectie 2: Anti-Stacking)
exec 200>/tmp/sovereign_monitor.lock
if ! flock -n 200; then
    exit 0
fi

# 3. Identity Guard (Sectie 2: Root Prevention)
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root."
    exit 1
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
            echo "Subject: ❌ Sovereign Monitor CRITICAL ERROR"
            echo "Content-Type: text/plain; charset=utf-8"
            echo ""
            printf "Critical Monitoring Failure:\n%b\n" "$msg"
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

# Logging setup - reached only after lock and guards
BACKUP_DIR="${DOCKER_ROOT}/backups"
LOG_FILE="${BACKUP_DIR}/cron.log"
exec >> "$LOG_FILE" 2>&1

log_message "--- Monitoring Routine Started ---"

# 5. System Health Metrics (Sectie 3: Telemetry)
TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
DISK=$(df -h "$DOCKER_ROOT" | awk 'NR==2 {print $5}')

# 6. Local Integrity Check (Find-based)
LATEST_LOCAL=$(find "$BACKUP_DIR" -maxdepth 1 -name "sovereign_stack_*.enc" -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -z "$LATEST_LOCAL" ]; then
    STATUS="ERROR: No local backup found."
else
    log_message "Verifying local integrity: $(basename "$LATEST_LOCAL")"
    if openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" -in "$LATEST_LOCAL" | tar -tzf - &> /dev/null; then
        STATUS="OK: Integrity verified."
    else
        STATUS="CRITICAL: Integrity check FAILED."
    fi
fi

# 7. Remote Verification (Sectie 3: WOL Utility & Networking)
CLEAN_IP=$(echo "$BACKUP_TARGET_IP" | sed -e 's|^http://||' -e 's|^https://||')
FILE_NAME=$(basename "$LATEST_LOCAL")
REMOTE_FULL_PATH="${BACKUP_TARGET_PATH}/${FILE_NAME}"

log_message "Ensuring target is awake for remote verification..."
if "${SCRIPT_DIR}/wake_target.sh" \
    "$BACKUP_TARGET_MAC" \
    "$CLEAN_IP" \
    "${BACKUP_MAX_RETRIES:-15}" \
    "${BACKUP_RETRY_WAIT:-6}"; then

    if [ "${BACKUP_TARGET_OS,,}" = "windows" ]; then
        # Remove leading slash for Windows CMD compatibility
        WIN_PATH=$(echo "$REMOTE_FULL_PATH" | sed 's/^\///')
        CHECK_CMD="if exist \"${WIN_PATH}\" (exit 0) else (exit 1)"
    else
        CHECK_CMD="test -f \"${REMOTE_FULL_PATH}\""
    fi

    if ssh -o BatchMode=yes "${BACKUP_TARGET_USER}@${CLEAN_IP}" "$CHECK_CMD"; then
        log_message "Remote file presence verified."
    else
        log_message "ERROR: Remote file not found on target: ${REMOTE_FULL_PATH}"
        STATUS="ERROR: Remote sync failed."
    fi
else
    log_message "WARN: Could not reach target for remote verification."
fi

# 8. Report Generation & Email Dispatch (Sectie 3: Reporting)
if [[ "$STATUS" == *"OK"* ]]; then
    SUBJECT="✅ Sovereign Backup Success ($TEMP)"
else
    SUBJECT="❌ ALERT: Sovereign Backup FAILED"
fi

REPORT_MAIL=$(mktemp)
{
    echo "To: ${BACKUP_EMAIL}"
    echo "Subject: ${SUBJECT}"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "Sovereign Health & Backup Report"
    echo "==============================="
    echo "Date:        $(date)"
    echo "Temperature: $TEMP"
    echo "Disk Usage:  $DISK"
    echo "Status:      $STATUS"
    echo ""
    echo "REPORT LOG (LAST 25 LINES):"
    echo "------------------------------------------------------------"
    tail -n 25 "$LOG_FILE"
    echo "------------------------------------------------------------"
    echo "End of Report."
} > "$REPORT_MAIL"

msmtp "${BACKUP_EMAIL}" < "$REPORT_MAIL"
rm "$REPORT_MAIL"

log_message "--- Monitoring Routine Finished ---"
