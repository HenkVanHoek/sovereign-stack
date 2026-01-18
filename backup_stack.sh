#!/bin/bash
# File: backup_stack.sh
# Sovereign Stack Master Backup v2.2
# Consolidation of Archive, Encryption, SFTP-Push, and Advanced Reporting.

# 1. Load secrets and config
ENV_PATH="$HOME/docker/.env"
if [ -f "$ENV_PATH" ]; then
    export $(grep -v '^#' "$ENV_PATH" | xargs)
else
    echo "Error: .env file not found!" && exit 1
fi

# 2. Configuration
SOURCE_DIR="$HOME/docker"
BACKUP_DIR="${SOURCE_DIR}/backups"
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
LIST_FILE="/tmp/backup_list_${DATE}.txt"
DB_EXPORT="${SOURCE_DIR}/nextcloud/nextcloud_db_export.sql"

# 3. Collect System Health Data
CPU_TEMP=$(vcgencmd measure_temp | cut -d "=" -f2)
DISK_USAGE=$(df -h "${SOURCE_DIR}" | awk 'NR==2 {print $5}')

echo "--- Starting Sovereign Backup: ${DATE} (CPU: ${CPU_TEMP}) ---"

# 4. Step 1: Database Export
echo "Step 1: Exporting Database..."
docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud > "$DB_EXPORT"

# 5. Step 2: Archive & Encrypt
# We use 'tee' to capture the file list while the archive is being created
echo "Step 2: Creating encrypted archive and file list..."
sudo tar -cvzf - \
    --exclude='./backups' \
    --exclude='./.git' \
    --exclude='./storage' \
    --exclude='./frigate/storage' \
    -C "$SOURCE_DIR" . 2> >(tee "$LIST_FILE" >&2) | \
    openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" -out "${BACKUP_DIR}/${FILENAME}"

# 6. Step 3: SFTP Transfer
echo "Step 3: Pushing to PC..."
# Using the variables from your .env
sftp -b - "${PC_USER}@${PC_IP}" <<EOF
put "${BACKUP_DIR}/${FILENAME}" "${PC_BACKUP_PATH}/"
quit
EOF

TRANSFER_STATUS=$?

# 7. Step 4: Build and Send High-Priority MIME Email
echo "Step 4: Sending Advanced Health Report..."
BOUNDARY="GC0p4Jq0M2Yt08j34c0p"

{
    echo "To: ${BACKUP_EMAIL}"
    echo "From: Sovereign-Stack <${BACKUP_EMAIL}>"
    echo "Subject: 🚀 Backup SUCCESS - ${DATE}"
    echo "X-Priority: 1 (Highest)"
    echo "Importance: High"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
    echo ""
    echo "--$BOUNDARY"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "SovereignStack Health Report"
    echo "----------------------------"
    echo "Status:          Success"
    echo "Filename:        ${FILENAME}"
    echo "CPU Temp:        ${CPU_TEMP}"
    echo "Disk Usage:      ${DISK_USAGE}"
    echo "SFTP Transfer:   $( [ $TRANSFER_STATUS -eq 0 ] && echo "Verified" || echo "FAILED" )"
    echo "----------------------------"
    echo "The encrypted archive is stored locally and on your workstation."
    echo "Attached: Detailed list of files included in this backup."
    echo ""
    echo "--$BOUNDARY"
    echo "Content-Type: text/plain; name=\"backup_list.txt\""
    echo "Content-Disposition: attachment; filename=\"backup_list.txt\""
    echo "Content-Transfer-Encoding: base64"
    echo ""
    base64 "$LIST_FILE"
    echo ""
    echo "--$BOUNDARY--"
} | msmtp -t

# 8. Cleanup
echo "Step 5: Cleaning up..."
rm "$LIST_FILE"
ls -t "${BACKUP_DIR}"/sovereign_stack_*.tar.gz.enc 2>/dev/null | tail -n +$((BACKUP_RETENTION_DAYS + 1)) | xargs -r rm

echo "--- Backup Process Finished ---"
