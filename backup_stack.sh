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

# sovereign-stack Selective Backup Pipeline v2.5

# Load Environment
ENV_PATH="/home/hvhoek/docker/.env"
if [ -f "$ENV_PATH" ]; then
    export $(grep -v '^#' "$ENV_PATH" | xargs)
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

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "--- Backup Routine Started: $(date) ---" >> "$LOG_FILE"

# 1. Database Export (Always include SQL for safety)
# We export the database to a flat file so it can be safely backed up while running.
echo "Exporting Nextcloud Database..." >> "$LOG_FILE"
docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" \
    nextcloud > "$DB_EXPORT"

# 2. Build Dynamic Excludes
# We always exclude local backups, git history, and raw DB files (redundant to SQL)
# Raw DB files are excluded because they are often locked/inconsistent during copy.
EXCLUDES="--exclude='./backups' --exclude='./.git' --exclude='./nextcloud/db' --exclude='./portainer/data'"

# Logic for Frigate Video Data
if [ "$INCLUDE_FRIGATE_DATA" != "true" ]; then
    EXCLUDES="$EXCLUDES --exclude='./storage'"
    echo "Mode: Excluding Frigate Videos" >> "$LOG_FILE"
else
    echo "Mode: Including Frigate Videos" >> "$LOG_FILE"
fi

# Logic for Nextcloud User Data
if [ "$INCLUDE_NEXTCLOUD_DATA" != "true" ]; then
    EXCLUDES="$EXCLUDES --exclude='./nextcloud/data'"
    echo "Mode: Excluding Nextcloud User Files" >> "$LOG_FILE"
else
    echo "Mode: Including Nextcloud User Files" >> "$LOG_FILE"
fi

# 3. Archive & Encrypt (AES-256-CBC with PBKDF2)
echo "Archiving and Encrypting..." >> "$LOG_FILE"
sudo tar -cvzf - $EXCLUDES -C "$DOCKER_ROOT" . | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" \
    -out "${BACKUP_DIR}/${FILENAME}"

# 4. SFTP Transfer to Remote PC
echo "Transferring to ${BACKUP_TARGET_OS} PC at ${PC_IP}..." >> "$LOG_FILE"
sftp -b - "${PC_USER}@${PC_IP}" <<EOF >> "$LOG_FILE" 2>&1
put "${BACKUP_DIR}/${FILENAME}" "${PC_BACKUP_PATH}/"
quit
EOF

# Check SFTP Exit Status
if [ $? -eq 0 ]; then
    echo "SUCCESS: Backup transferred to PC." >> "$LOG_FILE"
else
    echo "ERROR: SFTP Transfer failed. Check connection/permissions." >> "$LOG_FILE"
fi

# 5. Local Cleanup (Keep 7 days of local encrypted files)
find "$BACKUP_DIR" -name "sovereign_stack_*.enc" -mtime +7 -delete
echo "--- Backup Routine Finished: $(date) ---" >> "$LOG_FILE"
