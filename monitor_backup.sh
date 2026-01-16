#!/bin/bash
    # File: monitor_backup.sh
    # Sovereign Stack Monitor (Dead Man's Switch) - Generic Version
    # Features: Environment-aware paths, specific backup matching.

    # 1. Load variables from .env
    # We look for the .env in the standard location
    ENV_FILE="$HOME/docker/.env"
    if [ -f "$ENV_FILE" ]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    else
        echo "Error: .env file not found at $ENV_FILE"
        exit 1
    fi

    # 2. Configuration from environment
    # Using DOCKER_ROOT from .env ensures alignment with the backup script
    BACKUP_DIR="${DOCKER_ROOT}/backups"
    EMAIL="${BACKUP_EMAIL}"
    WINDOW="${MONITOR_WINDOW_MINS:-90}"

    # 3. Search for fresh backup files
    # Matches the exact pattern: sovereign_stack_YYYYMMDD_HHMMSS.tar.gz.enc
    RECENT_BACKUP=$(find "$BACKUP_DIR" -name "sovereign_stack_*.tar.gz.enc" -mmin -"$WINDOW" 2>/dev/null)

    # 4. Alert Logic
    if [ -z "$RECENT_BACKUP" ]; then
        SUBJECT="ALERT: Sovereign Backup Missing"
        BODY="Emergency Alert: No new backup file detected in ${BACKUP_DIR} within the last ${WINDOW} minutes.\n\nVerification required: The primary backup script may have failed silently or the system was offline."
        
        echo -e "Subject: ${SUBJECT}\n\n${BODY}" | msmtp "${EMAIL}"
        echo "[$(date)] Alert sent to ${EMAIL}"
    else
        echo "[$(date)] Health Check Passed: Fresh backup found in ${BACKUP_DIR}."
    fi
