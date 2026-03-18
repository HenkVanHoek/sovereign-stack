#!/bin/bash
# File: monitor_backup.sh
# Part of the sovereign-stack project.
# Version: 4.0.0 (Sovereign Awakening)
#
# ==============================================================================
# Sovereign Stack - Backup Monitor Script
# ==============================================================================
#
# DESCRIPTION:
# This script monitors the backup process by verifying:
# 1. Local backup integrity - checks if encrypted backup can be decrypted
# 2. Remote backup verification - checks if backup exists on remote target (NAS)
#
# WHAT IT CHECKS:
# 1. LOCAL INTEGRITY:
#    - Finds the latest backup file in backups directory
#    - Verifies the archive can be decrypted with the backup password
#
# 2. REMOTE VERIFICATION:
#    - Wakes the remote target via WoL (Wake-on-LAN)
#    - Checks if the backup file exists on the remote NAS
#    - Uses SSH to verify file presence
#
# DEPENDENCIES:
#    - openssl (for integrity verification)
#    - wake_target.sh script (for WoL)
#    - SSH access to remote target
#
# CONFIGURATION:
#    See .env for:
#    - BACKUP_ENCRYPTION_KEY: For encryption verification
#    - BACKUP_OFFSITE_IP: IP of off-site backup target
#    - BACKUP_OFFSITE_PATH: Path to backups on remote
#    - BACKUP_OFFSITE_OS: "linux" or "windows"
#    - BACKUP_OFFSITE_MAC: MAC address for WoL
#    - BACKUP_OFFSITE_WOL: Enable/disable WoL (YES/NO)
#
# OUTPUT:
#    - Sends email report to BACKUP_EMAIL
#    - Logs to /home/$USER/docker/backups/cron.log
#
# USAGE:
#    ./monitor_backup.sh
#
# SCHEDULED:
#    Via cron: 0 1 * * * /home/$USER/docker/monitor_backup.sh >> /home/$USER/docker/backups/cron.log 2>&1
#
# ==============================================================================
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
# along with this program.  If not, see https://www.gnu.org/licenses.
# ==============================================================================

# shellcheck disable=SC2154
set -u

# 1. Path Setup
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

# Set USER if not defined (needed for cron)
if [ -z "${USER:-}" ]; then
    USER=$(whoami)
fi

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
BACKUP_DIR="${BACKUP_LOCAL_TARGET}/archives"
LOG_FILE="${DOCKER_ROOT}/backups/cron.log"
exec >> "$LOG_FILE" 2>&1

log_message "--- Monitoring Routine Started ---"

# 5. System Health Metrics (Sectie 3: Telemetry)
TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
DISK=$(df -h "$DOCKER_ROOT" | awk 'NR==2 {print $5}')

# 6. Local Integrity Check (Find-based)
STATUS_LOCAL="NOT CHECKED"
LATEST_LOCAL=$(find "$BACKUP_DIR" -maxdepth 1 -name "sovereign_stack_*.enc" -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)

if [ -z "$LATEST_LOCAL" ]; then
    STATUS="ERROR: No local backup found."
else
    LOCAL_NAME=$(basename "$LATEST_LOCAL")
    log_message "Verifying LOCAL integrity: $LOCAL_NAME"
    # Verify local backup can be decrypted
    if openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_ENCRYPTION_KEY" -in "$LATEST_LOCAL" | tar -tzf - &> /dev/null; then
        STATUS_LOCAL="OK"
        # Calculate local checksum for comparison with off-site
        LOCAL_CHECKSUM=$(sha256sum "$LATEST_LOCAL" | awk '{print $1}')
        log_message "Local checksum: $LOCAL_CHECKSUM"
    else
        STATUS_LOCAL="FAILED"
        LOCAL_CHECKSUM=""
    fi
fi

# 7. Off-site Backup Verification
STATUS_NAS="NOT CHECKED"
CLEAN_IP=$(echo "$BACKUP_OFFSITE_IP" | sed -e 's|^http://||' -e 's|^https://||')

log_message "Ensuring off-site target is awake for remote verification..."
if [ "${BACKUP_OFFSITE_WOL:-YES}" = "YES" ]; then
    if ! "${SCRIPT_DIR}/wake_target.sh" \
        "${BACKUP_OFFSITE_MAC}" \
        "$CLEAN_IP" \
        "${BACKUP_OFFSITE_MAX_RETRIES:-15}" \
        "${BACKUP_OFFSITE_RETRY_WAIT:-6}"; then
        STATUS="ERROR: Could not reach off-site target"
    fi
fi

# Check if we should continue (either WoL disabled or wake succeeded)
if [ "${BACKUP_OFFSITE_WOL:-YES}" != "YES" ] || [ "${STATUS:-}" != "ERROR: Could not reach off-site target" ]; then
    # Find latest backup on off-site target
    log_message "Checking off-site target for latest backup..."
    if [ -n "${BACKUP_OFFSITE_PASSWORD:-}" ]; then
        LATEST_NAS=$(sshpass -p "$BACKUP_OFFSITE_PASSWORD" ssh -o StrictHostKeyChecking=accept-new \
            "$BACKUP_OFFSITE_USER@$CLEAN_IP" \
            "ls -t $BACKUP_OFFSITE_PATH/sovereign_stack_*.enc 2>/dev/null | head -1" 2>/dev/null)
    else
        LATEST_NAS=$(ssh "$BACKUP_OFFSITE_USER@$CLEAN_IP" \
            "ls -t $BACKUP_OFFSITE_PATH/sovereign_stack_*.enc 2>/dev/null | head -1" 2>/dev/null)
    fi
    
    if [ -n "$LATEST_NAS" ]; then
        NAS_NAME=$(basename "$LATEST_NAS")
        NAS_FULL_PATH="${BACKUP_OFFSITE_PATH}/${NAS_NAME}"
        
        # Check if local and off-site backups have the same filename (same backup)
        if [ "$LOCAL_NAME" = "$NAS_NAME" ]; then
            log_message "Comparing checksums for: $NAS_NAME"
            
            # Calculate checksum on off-site target
            if [ -n "${BACKUP_OFFSITE_PASSWORD:-}" ]; then
                NAS_CHECKSUM=$(sshpass -p "$BACKUP_OFFSITE_PASSWORD" ssh -o StrictHostKeyChecking=accept-new \
                    "$BACKUP_OFFSITE_USER@$CLEAN_IP" "sha256sum $NAS_FULL_PATH" 2>/dev/null | awk '{print $1}')
            else
                NAS_CHECKSUM=$(ssh "$BACKUP_OFFSITE_USER@$CLEAN_IP" \
                    "sha256sum $NAS_FULL_PATH" 2>/dev/null | awk '{print $1}')
            fi
            
            log_message "Off-site checksum: ${NAS_CHECKSUM:-'FAILED'}"
            
            # Compare checksums
            if [ -n "$LOCAL_CHECKSUM" ] && [ -n "$NAS_CHECKSUM" ]; then
                if [ "$LOCAL_CHECKSUM" = "$NAS_CHECKSUM" ]; then
                    STATUS_NAS="OK (checksum match)"
                else
                    STATUS_NAS="FAILED (checksum mismatch)"
                fi
            else
                STATUS_NAS="FAILED (checksum error)"
            fi
        else
            # Different filenames - just verify off-site exists and is valid
            log_message "Off-site has different backup: $NAS_NAME"
            if [ -n "${BACKUP_OFFSITE_PASSWORD:-}" ]; then
                NAS_CHECKSUM=$(sshpass -p "$BACKUP_OFFSITE_PASSWORD" ssh -o StrictHostKeyChecking=accept-new \
                    "$BACKUP_OFFSITE_USER@$CLEAN_IP" "sha256sum $NAS_FULL_PATH" 2>/dev/null | awk '{print $1}')
            else
                NAS_CHECKSUM=$(ssh "$BACKUP_OFFSITE_USER@$CLEAN_IP" \
                    "sha256sum $NAS_FULL_PATH" 2>/dev/null | awk '{print $1}')
            fi
            
            if [ -n "$NAS_CHECKSUM" ]; then
                STATUS_NAS="OK (different backup: $NAS_NAME)"
            else
                STATUS_NAS="FAILED"
            fi
        fi
    else
        STATUS_NAS="NOT FOUND"
    fi
    
    # Report status
    if [ "$STATUS_LOCAL" = "OK" ] && [[ "$STATUS_NAS" == OK* ]]; then
        STATUS="OK: Local and off-site backup verified"
    elif [ "$STATUS_LOCAL" = "OK" ] && [ "$STATUS_NAS" = "NOT FOUND" ]; then
        STATUS="WARNING: Local OK, off-site empty"
    else
        STATUS="ERROR: Local=$STATUS_LOCAL, Off-site=$STATUS_NAS"
    fi
fi
    
# 8. Report Generation & Email Dispatch (Sectie 3: Reporting)
if [[ "$STATUS" == ERROR:* ]]; then
    SUBJECT="❌ ALERT: Sovereign Backup FAILED"
elif [[ "$STATUS" == WARNING:* ]]; then
    SUBJECT="⚠️ Sovereign Backup WARNING"
else
    SUBJECT="✅ Sovereign Backup Success ($TEMP)"
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
