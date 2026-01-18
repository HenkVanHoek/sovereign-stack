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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Sovereign Stack Monitor (Dead Man's Switch) - v2.2
# Features: Environment-aware paths, High-Priority alerts, and System Load diagnostics.

# 1. Load variables from .env
# We look for the .env in the standard location to ensure alignment 
# with the central project configuration.
ENV_FILE="$HOME/docker/.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# 2. Configuration from environment
# Using DOCKER_ROOT ensures we are looking in the correct volume path.
# We also capture the current system load to aid in remote troubleshooting.
BACKUP_DIR="${DOCKER_ROOT}/backups"
EMAIL="${BACKUP_EMAIL}"
WINDOW="${MONITOR_WINDOW_MINS:-90}"
CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1)

# 3. Search for fresh backup files
# Matches the exact pattern: sovereign_stack_YYYYMMDD_HHMMSS.tar.gz.enc
# The -mmin -"$WINDOW" flag checks for files created within the last X minutes.
RECENT_BACKUP=$(find "$BACKUP_DIR" -name "sovereign_stack_*.tar.gz.enc" -mmin -"$WINDOW" 2>/dev/null)

# 4. Alert Logic
# If no file is found, we trigger a High-Priority email via msmtp.
if [ -z "$RECENT_BACKUP" ]; then
    SUBJECT="⚠️ ALERT: Sovereign Backup Missing"
    
    echo "--- [$(date)] Backup missing! Sending High-Priority alert to ${EMAIL} ---"
    
    {
        echo "To: ${EMAIL}"
        echo "From: Sovereign-Monitor <${EMAIL}>"
        echo "Subject: ${SUBJECT}"
        echo "X-Priority: 1 (Highest)"
        echo "Importance: High"
        echo ""
        echo "Emergency Alert: Dead Man's Switch Triggered."
        echo "------------------------------------------------"
        echo "No new backup file detected in: ${BACKUP_DIR}"
        echo "Monitoring Window:            ${WINDOW} minutes"
        echo "Current System Load:          ${CPU_LOAD}"
        echo "------------------------------------------------"
        echo "Verification required: The primary backup script may have failed 
internally, or the SFTP push process stalled the pipeline."
        echo ""
        echo "Suggested Action: Check ~/docker/backup_push.log for errors."
    } | msmtp "${EMAIL}"

    echo "[$(date)] Alert sent."
else
    # 5. Health Check Passed
    # If a file exists, we log the success to stdout (captured by cron logs).
    echo "[$(date)] Health Check Passed: Fresh backup found in ${BACKUP_DIR}."
fi
