#!/bin/bash
# File: backup_stack.sh
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

# sovereign-stack Selective Backup Pipeline v3.2
set -u

# Load Environment and strip Windows hidden characters (\r)
ENV_PATH="/home/hvhoek/docker/.env"
if [ -f "$ENV_PATH" ]; then
    # More robust way to load .env in Bash
    set -a
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    echo "Error: .env file not found at $ENV_PATH"
    exit 1
fi

# Paths & Vars
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
BACKUP_DIR="${DOCKER_ROOT}/backups"
LOG_FILE="${BACKUP_DIR}/cron.log"
DB_EXPORT="${DOCKER_ROOT}/nextcloud/nextcloud_db_export.sql"

mkdir -p "$BACKUP_DIR"

log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

log_message "--- Backup Routine Started ---"

# 1. System Health Check
RAW_TEMP=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
TEMP_INT=${RAW_TEMP%.*}
TEMP_DISPLAY="${RAW_TEMP}'C"
DISK_USAGE=$(df -h "${DOCKER_ROOT}" | awk 'NR==2 {print $5}')

log_message "System Status: Temp=$TEMP_DISPLAY | Disk=$DISK_USAGE"

# 2. Database Export
log_message "Exporting Nextcloud Database..."
docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" \
    nextcloud > "$DB_EXPORT" 2>> "$LOG_FILE"

# 3. Build Dynamic Excludes
EXCLUDES=(
    "--exclude=backups"
    "--exclude=.git"
    "--exclude=nextcloud/db"
    "--exclude=portainer/data"
)

if [ "${INCLUDE_FRIGATE_DATA:-false}" != "true" ]; then
    EXCLUDES+=("--exclude=storage")
    log_message "Mode: Excluding Frigate Videos (storage folder)"
fi

if [ "${INCLUDE_NEXTCLOUD_DATA:-false}" != "true" ]; then
    EXCLUDES+=("--exclude=nextcloud/data")
    log_message "Mode: Excluding Nextcloud User Files"
fi

# 4. Archive & Encrypt
log_message "Archiving and Encrypting..."
sudo tar "${EXCLUDES[@]}" -cvzf - -C "$DOCKER_ROOT" . 2>> "$LOG_FILE" | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" \
    -out "${BACKUP_DIR}/${FILENAME}" 2>> "$LOG_FILE"

# 5. SFTP Transfer
log_message "Transferring to ${BACKUP_TARGET_OS} PC..."
BATCH_FILE=$(mktemp)
# Ensure the path starts with a slash to indicate an absolute Windows path
REMOTE_PATH="${PC_BACKUP_PATH}"
[[ "$REMOTE_PATH" != /* ]] && REMOTE_PATH="/$REMOTE_PATH"

echo "put ${BACKUP_DIR}/${FILENAME} ${REMOTE_PATH}/" > "$BATCH_FILE"
echo "quit" >> "$BATCH_FILE"

# SSH commando's gebruiken geen http:// prefix
CLEAN_IP=$(echo "$PC_IP" | sed 's|http://||g')
sftp -b "$BATCH_FILE" "${PC_USER}@${CLEAN_IP}" >> "$LOG_FILE" 2>&1
SFTP_STATUS=$?
rm "$BATCH_FILE"

# 6. Local Cleanup
log_message "Cleaning up local archives older than 7 days..."
find "$BACKUP_DIR" -name "sovereign_stack_*.enc" -mtime +7 -delete >> "$LOG_FILE" 2>&1

# 7. Final Status & Email Priority Logic
PRIORITY="Normal"
PRIORITY_HEADER="3"

if [ $SFTP_STATUS -eq 0 ]; then
    STATUS_MSG="SUCCESS: Backup transferred to PC."
    SUBJECT="✅ Sovereign Backup Success ($TEMP_DISPLAY)"
else
    STATUS_MSG="ERROR: Backup transfer FAILED. Check cron.log for details."
    SUBJECT="❌ ALERT: Sovereign Backup FAILED"
    PRIORITY="High"
    PRIORITY_HEADER="1"
fi

if [ "$TEMP_INT" -ge 80 ]; then
    SUBJECT="⚠️ CRITICAL TEMP: Sovereign Backup Alert ($TEMP_DISPLAY)"
    PRIORITY="High"
    PRIORITY_HEADER="1"
fi

log_message "$STATUS_MSG"
log_message "--- Backup Routine Finished ---"

# 8. Send Email
TEMP_MAIL=$(mktemp)
{
    echo "To: ${BACKUP_EMAIL}"
    echo "Subject: ${SUBJECT}"
    echo "X-Priority: ${PRIORITY_HEADER}"
    echo "Importance: ${PRIORITY}"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "Sovereign Health & Backup Report"
    echo "==============================="
    echo "Date:        $(date)"
    echo "Temperature: $TEMP_DISPLAY"
    echo "Disk Usage:  $DISK_USAGE"
    echo "Status:      ${STATUS_MSG}"
    echo "Filename:    ${FILENAME}"
    echo ""
    echo "FULL LOG FOR THIS RUN:"
    echo "------------------------------------------------------------"
    # Extract last run using the header we defined
    sed -n "/--- Backup Routine Started/,/--- Backup Routine Finished/p" "$LOG_FILE" | tail -n 50
    echo "------------------------------------------------------------"
    echo "End of Report."
} > "$TEMP_MAIL"

cat "$TEMP_MAIL" | msmtp "${BACKUP_EMAIL}"
rm "$TEMP_MAIL"
