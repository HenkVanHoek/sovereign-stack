#!/bin/bash
# File: monitor_backup.sh
# Part of the sovereign-stack project.
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.

ENV_PATH="/home/hvhoek/docker/.env"
[ -f "$ENV_PATH" ] && export $(grep -v '^#' "$ENV_PATH" | xargs)

# We check the PC for files modified in the last 120 minutes (giving overhead)
# This command returns the count of files found
REMOTE_COUNT=$(ssh -o ConnectTimeout=15 "${PC_USER}@${PC_IP}" "find ${PC_BACKUP_PATH} -name 'sovereign_stack_*.enc' -mmin -120 | wc -l")

if [ "$REMOTE_COUNT" -eq 0 ]; then
    # FAILURE: No fresh file found on the remote PC
    {
        echo "To: ${BACKUP_EMAIL}"
        echo "Subject: ⚠️ ALERT: Sovereign Backup NOT FOUND on PC"
        echo "X-Priority: 1 (Highest)"
        echo "Importance: High"
        echo ""
        echo "The Dead Man's Switch triggered at $(date)."
        echo "No backup file was detected on the remote PC at ${PC_IP}."
        echo ""
        echo "Please check if the PC is powered on and the SFTP service is running."
        echo "Last lines of Pi cron.log:"
        tail -n 10 "${DOCKER_ROOT}/backups/cron.log"
    } | msmtp "${BACKUP_EMAIL}"
else
    echo "Monitor Success: Fresh backup found on remote PC."
fi
