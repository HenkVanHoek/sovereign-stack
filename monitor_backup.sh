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

# Cross-Platform Dead Man's Switch v2.5

ENV_PATH="/home/hvhoek/docker/.env"
[ -f "$ENV_PATH" ] && export $(grep -v '^#' "$ENV_PATH" | xargs)

# Determine the remote command based on OS
case "${BACKUP_TARGET_OS}" in
    windows)
        # Windows PowerShell logic (escaped for Bash)
        CMD="powershell.exe -Command \"(Get-ChildItem -Path '${PC_BACKUP_PATH}' -Filter 'sovereign_stack_*.enc' | Where-Object { \$_.LastWriteTime -gt (Get-Date).AddMinutes(-120) }).Count\""
        ;;
    linux|mac)
        # Linux/Mac find logic
        CMD="find ${PC_BACKUP_PATH} -name 'sovereign_stack_*.enc' -mmin -120 | wc -l"
        ;;
    *)
        echo "Error: Unknown BACKUP_TARGET_OS: ${BACKUP_TARGET_OS}"
        exit 1
        ;;
esac

# Execute SSH command and strip potential Windows carriage returns
REMOTE_COUNT=$(ssh -o ConnectTimeout=15 "${PC_USER}@${PC_IP}" "$CMD" | tr -d '\r' | xargs)

# Safety check for empty result (e.g. connection timeout)
[[ -z "$REMOTE_COUNT" ]] && REMOTE_COUNT=0

if [ "$REMOTE_COUNT" -eq 0 ]; then
    # FAILURE: Send High-Priority Alert
    {
        echo "To: ${BACKUP_EMAIL}"
        echo "Subject: ⚠️ ALERT: Sovereign Backup NOT FOUND on PC"
        echo "X-Priority: 1 (Highest)"
        echo "Importance: High"
        echo ""
        echo "The Dead Man's Switch triggered at $(date)."
        echo "No backup file found on the ${BACKUP_TARGET_OS} machine (${PC_IP})."
        echo "Path checked: ${PC_BACKUP_PATH}"
        echo ""
        echo "Last 10 lines of local cron.log:"
        tail -n 10 "/home/hvhoek/docker/backups/cron.log"
    } | msmtp "${BACKUP_EMAIL}"
else
    echo "Monitor Success: Found $REMOTE_COUNT fresh backup(s) on ${BACKUP_TARGET_OS} PC."
fi
