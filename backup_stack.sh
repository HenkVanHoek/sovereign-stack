#!/bin/bash
# File: backup_stack.sh
# Part of the sovereign-stack project.
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.

# Load Env
ENV_PATH="/home/hvhoek/docker/.env"
[ -f "$ENV_PATH" ] && export $(grep -v '^#' "$ENV_PATH" | xargs)

DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
BACKUP_DIR="${DOCKER_ROOT}/backups"
DB_EXPORT="${DOCKER_ROOT}/nextcloud/nextcloud_db_export.sql"
LOG_FILE="${BACKUP_DIR}/cron.log"

echo "--- Backup Started: $(date) ---" >> "$LOG_FILE"

# 1. Database Export
docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud > "$DB_EXPORT"

# 2. Archive & Encrypt
sudo tar -cvzf - --exclude='./backups' --exclude='./storage' -C "$DOCKER_ROOT" . | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" -out "${BACKUP_DIR}/${FILENAME}"

# 3. SFTP Push to PC
sftp -b - "${PC_USER}@${PC_IP}" <<EOF >> "$LOG_FILE" 2>&1
put "${BACKUP_DIR}/${FILENAME}" "${PC_BACKUP_PATH}/"
quit
EOF

if [ $? -eq 0 ]; then
    echo "SUCCESS: Transfer to PC completed." >> "$LOG_FILE"
else
    echo "ERROR: Transfer to PC failed." >> "$LOG_FILE"
fi

# Cleanup local encrypted files older than retention (optional, as the PC is the master)
find "$BACKUP_DIR" -name "sovereign_stack_*.enc" -mtime +7 -delete
