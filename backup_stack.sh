#!/bin/bash
    # file: backup_stack.sh
    # Sovereign Stack Backup Tool v2.1
    # Features: Sudo-enabled, media-excluded, encrypted, SFTP-push, and email-notified.

    # 1. Load secrets and config from .env
    # Using absolute path to ensure cron compatibility
    ENV_PATH="$HOME/docker/.env"
    if [ -f "$ENV_PATH" ]; then
        export $(grep -v '^#' "$ENV_PATH" | xargs)
    else
        echo "Error: .env file not found at $ENV_PATH!"
        exit 1
    fi

    # 2. Configuration
    SOURCE_DIR="$HOME/docker"
    BACKUP_DIR="${SOURCE_DIR}/backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
    
    # Nextcloud DB Export Path
    DB_EXPORT="${SOURCE_DIR}/nextcloud/nextcloud_db_export.sql"
    
    # Use variables from .env or fallbacks
    EMAIL="${BACKUP_EMAIL:-hvh@freedom.nl}"
    PASSWORD="${BACKUP_PASSWORD}"
    RETENTION="${BACKUP_RETENTION_DAYS:-7}"

    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR"

    # 3. Helper function for notifications
    send_notification() {
        local subject="$1"
        local message="$2"
        echo -e "Subject: ${subject}\n\n${message}" | msmtp "${EMAIL}"
    }

    echo "--- Starting Sovereign Backup: ${DATE} ---"

    # 4. Database Export (Pre-archive)
    echo "Step 1: Exporting Nextcloud Database..."
    docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud > "$DB_EXPORT"

    # 5. The Core Command: sudo tar + encryption
    # We strictly keep all exclusions to manage size and CPU load
    echo "Step 2: Creating encrypted archive..."
    sudo tar -czf - \
        --exclude='./backups' \
        --exclude='./.git' \
        --exclude='./storage' \
        --exclude='./frigate/storage' \
        -C "$SOURCE_DIR" . | \
        openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$PASSWORD" -out "${BACKUP_DIR}/${FILENAME}"

    # 6. SFTP Transfer to Windows Workstation
    echo "Step 3: Transferring to Windows PC..."
    echo "put ${BACKUP_DIR}/${FILENAME} ${PC_BACKUP_PATH}/" | sftp "${PC_USER}@${PC_IP}"

    # 7. Verification and Reporting
    if [ $? -eq 0 ]; then
        SIZE=$(ls -lh "${BACKUP_DIR}/${FILENAME}" | awk '{print $5}')
        
        # 4a. Get Disk usage for the report
        DISK_USAGE=$(df -h -x tmpfs -x devtmpfs -x squashfs)
        
        echo "Success! Size: $SIZE"
        
        # Send success email with Disk Usage included
        send_notification "Backup SUCCESS: Sovereign Stack" \
            "The daily backup was successful.\n\nFilename: ${FILENAME}\nSize: ${SIZE}\nLocation: ${BACKUP_DIR}\n\n--- Current Disk Usage ---\n${DISK_USAGE}"

        # 8. Cleanup: Remove files older than the retention period
        echo "Step 4: Cleaning up old local backups (Retention: ${RETENTION} days)..."
        ls -t "${BACKUP_DIR}"/sovereign_stack_*.tar.gz.enc 2>/dev/null | tail -n +$((RETENTION + 1)) | xargs -r rm
    else
        echo "Error: Backup failed!"
        send_notification "Backup FAILED: Sovereign Stack" \
            "The backup attempted on $(date) has failed. Please check the logs."
        exit 1
    fi

    echo "--- Backup Completed: $(date) ---"
