#!/bin/bash
    # File: push_backus_to_pc.sh
    # SovereignStack Backup Pipeline - piselfhosting.com

    # --- Configuration ---
    # Load environment variables from the central .env file
    ENV_FILE="$HOME/docker/.env"
    if [ -f "$ENV_FILE" ]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    else
        echo "Error: .env file not found at $ENV_FILE"
        exit 1
    fi

    # Set dynamic paths and timestamps
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    SOURCE_DIR="$HOME/docker"
    LOCAL_BACKUP_DIR="$SOURCE_DIR/backups"
    EXPORT_FILE="$SOURCE_DIR/nextcloud/nextcloud_db_export.sql"
    
    mkdir -p "$LOCAL_BACKUP_DIR"
    OUT_FILE="$LOCAL_BACKUP_DIR/sovereign_stack_$TIMESTAMP.tar.gz"
    ENC_FILE="$OUT_FILE.enc"

    # --- Error Handling Function ---
    # Sends an email notification if any critical step fails
    notify_error() {
        local message="$1"
        echo "Error during backup: $message"
        echo "The SovereignStack backup failed on $(date). Error: $message" | \
        mail -s "BACKUP FAILED: $(hostname)" "$BACKUP_EMAIL"
        exit 1
    }

    echo "--- Starting SovereignStack Backup: $TIMESTAMP ---"

    # Step 1: Database Export (MariaDB)
    echo "Step 1: Performing MariaDB dump for Nextcloud..."
    docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" \
        nextcloud > "$EXPORT_FILE" || notify_error "MariaDB dump failed"

    # Step 2: Create Archive (tar)
    # Excluding backups, storage, and frigate media
    echo "Step 2: Archiving $SOURCE_DIR..."
    sudo tar --exclude='./backups' \
             --exclude='./storage' \
             --exclude='./frigate/storage' \
             -czf "$OUT_FILE" -C "$SOURCE_DIR" . || notify_error "Tar archive failed"

    # Step 3: Automated Encryption (PBKDF2)
    # Using BACKUP_PASSWORD from your .env
    echo "Step 3: Encrypting archive..."
    sudo openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$OUT_FILE" \
        -out "$ENC_FILE" \
        -pass pass:"$BACKUP_PASSWORD" || notify_error "Encryption failed"

    # Step 4: Permission Adjustment
    sudo chown $USER:$USER "$ENC_FILE"

    # Step 5: Remote Transfer (SFTP)
    echo "Step 5: Transferring to $PC_USER@$PC_IP..."
    echo "put $ENC_FILE $PC_BACKUP_PATH/" | sftp "$PC_USER@$PC_IP" || notify_error "SFTP transfer failed"

    # Step 6: Local Retention Cleanup
    # Deleting local backups older than the specified retention days
    echo "Step 6: Cleaning up local backups older than $BACKUP_RENTATION_DAYS days..."
    find "$LOCAL_BACKUP_DIR" -type f -name "*.enc" -mtime +"$BACKUP_RENTATION_DAYS" -exec rm {} \;
    
    # Step 7: Final Cleanup of temporary files
    echo "Step 7: Cleaning up temporary local files..."
    sudo rm "$OUT_FILE"
    rm "$ENC_FILE"

    echo "--- Backup Completed successfully at $(date) ---"
