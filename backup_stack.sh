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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# sovereign-stack Selective Backup Pipeline v2.3

# Load Environment
ENV_PATH="/home/hvhoek/docker/.env"
[ -f "$ENV_PATH" ] && export $(grep -v '^#' "$ENV_PATH" | xargs)

# Paths & Vars
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
BACKUP_DIR="${DOCKER_ROOT}/backups"
LOG_FILE="${BACKUP_DIR}/cron.log"
DB_EXPORT="${DOCKER_ROOT}/nextcloud/nextcloud_db_export.sql"

echo "--- Backup Routine Started: $(date) ---" >> "$LOG_FILE"

# 1. Database Export (Always include SQL for safety)
echo "Exporting Nextcloud Database..." >> "$LOG_FILE"
docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" \
    nextcloud > "$DB_EXPORT"

# 2. Build Dynamic Excludes
# We always exclude local backups, git history, and raw DB files (redundant to SQL)
EXCLUDES="--exclude='./backups' --exclude='./.git' --exclude='./nextcloud/db'"

if [ "$INCLUDE_FRIGATE_DATA" != "true" ]; then
    EXCLUDES="$EXCLUDES --exclude='./storage'"
    echo "Mode: Excluding Frigate Videos" >> "$LOG_FILE"
fi

if [ "$INCLUDE_NEXTCLOUD_DATA" != "true" ]; then
    EXCLUDES="$EXCLUDES --exclude='./nextcloud/data'"
    echo "Mode: Excluding Nextcloud User Files" >> "$LOG_FILE"
else
    echo "Mode: Including Nextcloud User Files" >> "$LOG_FILE"
fi

# 3. Archive & Encrypt (AES-256-CBC)
echo "Archiving and Encrypting..." >> "$LOG_FILE"
sudo tar -cvzf - $EXCLUDES -C "$DOCKER_ROOT" . | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" \
    -out "${BACKUP_DIR}/${FILENAME}"

# 4. SFTP Transfer to PC
echo "Transferring to PC at ${PC_IP}..." >> "$LOG_FILE"
sftp -b - "${PC_USER}@${PC_IP}" <<EOF >> "$LOG_FILE" 2>&1
put "${BACKUP_DIR}/${FILENAME}" "${PC_BACKUP_PATH}/"
quit
EOF

if [ $? -eq 0 ]; then
    echo "SUCCESS: Backup transferred to PC." >> "$LOG_FILE"
else
    echo "ERROR: SFTP Transfer failed." >> "$LOG_FILE"
fi

# 5. Local Cleanup (Keep 7 days locally)
find "$BACKUP_DIR" -name "sovereign_stack_*.enc" -mtime +7 -delete
echo "--- Backup Routine Finished: $(date) ---" >> "$LOG_FILE"
