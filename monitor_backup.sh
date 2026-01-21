#!/bin/bash
# File: monitor_backup.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for full license text.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# Cross-Platform Dead Man's Switch & Integrity Check v3.3
set -u

LOG_FILE="/home/hvhoek/docker/backups/cron.log"
ENV_PATH="/home/hvhoek/docker/.env"

# 1. Robust Environment Loader
if [ -f "$ENV_PATH" ]; then
    set -a
    # Gebruik van process substitution vereist BASH
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    echo "$(date): ERROR - .env file not found at $ENV_PATH" | tee -a "$LOG_FILE"
    exit 1
fi

# 2. Local Integrity Check
# Verify the most recent local backup can be decrypted and is not corrupt
BACKUP_DIR="${DOCKER_ROOT}/backups"
LATEST_LOCAL=$(ls -t "${BACKUP_DIR}"/sovereign_stack_*.enc 2>/dev/null | head -n 1)

if [ -z "$LATEST_LOCAL" ]; then
    LOCAL_STATUS="FAILED (No local file found)"
    INTEGRITY_PASSED=false
else
    # Decrypt in memory and test tar structure without writing to disk
    openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" \
        -in "$LATEST_LOCAL" 2>/dev/null | tar -tzf - > /dev/null
    if [ $? -eq 0 ]; then
        LOCAL_STATUS="PASSED"
        INTEGRITY_PASSED=true
    else
        LOCAL_STATUS="CORRUPT (Decryption or Archive error)"
        INTEGRITY_PASSED=false
    fi
fi

# 3. Clean IP address (remove http/https prefix if present)
CLEAN_IP=$(echo "$PC_IP" | sed -e 's|^http://||' -e 's|^https://||')

# 4. Determine the remote command based on OS
case "${BACKUP_TARGET_OS}" in
    windows)
        # Remove leading slash for PowerShell (e.g., /H:/ becomes H:/)
        WIN_PATH="${PC_BACKUP_PATH#/}"
        CMD="powershell.exe -Command \"(Get-ChildItem -Path '${WIN_PATH}' -Filter 'sovereign_stack_*.enc' | Where-Object { \$_.LastWriteTime -gt (Get-Date).AddMinutes(-120) }).Count\""
        ;;
    linux|mac)
        CMD="find ${PC_BACKUP_PATH} -name 'sovereign_stack_*.enc' -mmin -120 | wc -l"
        ;;
    *)
        echo "$(date): ERROR - Unknown BACKUP_TARGET_OS: '${BACKUP_TARGET_OS}'" | tee -a "$LOG_FILE"
        exit 1
        ;;
esac

# 5. Execute SSH command and capture the exit code of SSH specifically
# We capture raw output first to separate SSH status from command output
RAW_OUTPUT=$(ssh -o ConnectTimeout=15 "${PC_USER}@${CLEAN_IP}" "$CMD" 2>/dev/null)
SSH_EXIT_CODE=$?

# Clean the output (remove carriage returns and whitespace)
REMOTE_COUNT=$(echo "$RAW_OUTPUT" | tr -d '\r' | xargs)

# 6. Determine Status
if [ "$INTEGRITY_PASSED" = false ]; then
    STATUS="FAILURE: Local backup integrity check $LOCAL_STATUS."
    FILE_FOUND=false
elif [ "$SSH_EXIT_CODE" -ne 0 ]; then
    STATUS="CRITICAL: SSH connection failed to ${CLEAN_IP} (Check if PC is ON)"
    FILE_FOUND=false
elif [[ -z "$REMOTE_COUNT" ]] || ! [[ "$REMOTE_COUNT" =~ ^[0-9]+$ ]]; then
    STATUS="FAILURE: Unexpected response from ${CLEAN_IP}. Could not verify backup."
    FILE_FOUND=false
elif [ "$REMOTE_COUNT" -eq 0 ]; then
    STATUS="FAILURE: No fresh backup files found on ${CLEAN_IP} in the last 120 min."
    FILE_FOUND=false
else
    STATUS="SUCCESS: Local integrity OK and $REMOTE_COUNT backup(s) found on ${CLEAN_IP}."
    FILE_FOUND=true
fi

# 7. Log the result
echo "$(date): $STATUS" | tee -a "$LOG_FILE"

# 8. Send alert on failure
if [ "$FILE_FOUND" = false ]; then
    {
        echo "To: ${BACKUP_EMAIL}"
        echo "Subject: ⚠️ ALERT: Sovereign Backup Status - $STATUS"
        echo "X-Priority: 1 (Highest)"
        echo "Importance: High"
        echo "MIME-Version: 1.0"
        echo "Content-Type: text/plain; charset=utf-8"
        echo ""
        echo "The Dead Man's Switch triggered at $(date)."
        echo "Status:          $STATUS"
        echo "Local Integrity: $LOCAL_STATUS"
        echo "Path checked:    ${PC_BACKUP_PATH} on host ${CLEAN_IP}"
        echo ""
        echo "Last 10 lines of cron.log:"
        tail -n 10 "$LOG_FILE"
    } | msmtp "${BACKUP_EMAIL}"
fi