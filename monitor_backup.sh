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

# Cross-Platform Dead Man's Switch v3.1
set -u

LOG_FILE="/home/hvhoek/docker/backups/cron.log"
ENV_PATH="/home/hvhoek/docker/.env"

# Robust Environment Loader
if [ -f "$ENV_PATH" ]; then
    set -a
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    echo "$(date): ERROR - .env file not found at $ENV_PATH" | tee -a "$LOG_FILE"
    exit 1
fi

# Determine the remote command based on OS
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

# Execute SSH command and check status
REMOTE_COUNT=$(ssh -o ConnectTimeout=15 "${PC_USER}@${PC_IP}" "$CMD" 2>/dev/null | tr -d '\r' | xargs)
SSH_EXIT_CODE=$?

if [ "$SSH_EXIT_CODE" -ne 0 ]; then
    STATUS="CRITICAL: SSH connection failed to ${PC_IP} (Exit code: $SSH_EXIT_CODE)"
    FILE_FOUND=false
elif [[ -z "$REMOTE_COUNT" ]] || [ "$REMOTE_COUNT" -eq 0 ]; then
    STATUS="FAILURE: No fresh backup files found on ${PC_IP}"
    FILE_FOUND=false
else
    STATUS="SUCCESS: Found $REMOTE_COUNT fresh backup(s) on ${PC_IP}."
    FILE_FOUND=true
fi

# Log the result to local cron.log AND show on screen
echo "$(date): $STATUS" | tee -a "$LOG_FILE"

# Send alert on failure
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
        echo "Status: $STATUS"
        echo "Path checked: ${PC_BACKUP_PATH}"
        echo ""
        echo "Last 10 lines of cron.log:"
        tail -n 10 "$LOG_FILE"
    } | msmtp "${BACKUP_EMAIL}"
fi