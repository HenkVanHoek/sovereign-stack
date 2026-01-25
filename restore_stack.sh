#!/bin/bash
# File: restore_stack.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
# sovereign-stack Disaster Recovery Utility v3.2
set -u

# 1. Load Environment Dynamically
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source <(sed 's/\r$//' "$ENV_FILE")
    set +a
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# 2. Paths & Variables
BACKUP_DIR="${DOCKER_ROOT}/backups"
TEMP_RESTORE="/tmp/sovereign_restore"
DB_EXPORT_PATH="${DOCKER_ROOT}/nextcloud/nextcloud_db_export.sql"

echo "--- Sovereign Stack: Disaster Recovery Utility ---"

# 3. Select Backup File
echo "Available backups in $BACKUP_DIR:"
# Fixed ShellCheck warning by using find instead of ls
find "$BACKUP_DIR" -maxdepth 1 -name "*.enc" -exec basename {} \;
echo ""
read -r -p "Enter the full filename of the backup to restore: " SELECTED_BACKUP

FULL_PATH="${BACKUP_DIR}/${SELECTED_BACKUP}"

if [ ! -f "$FULL_PATH" ]; then
    echo "Error: File $FULL_PATH not found."
    exit 1
fi

# 4. Decryption & Extraction
echo "Step 1/4: Decrypting and extracting backup..."
mkdir -p "$TEMP_RESTORE"

if openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" -in "$FULL_PATH" | \
   tar -xvzf - -C "$TEMP_RESTORE"; then
    echo "[OK] Decryption and extraction successful."
else
    echo "[ERROR] Decryption failed. Is the password correct?"
    rm -rf "$TEMP_RESTORE"
    exit 1
fi

# 5. File Synchronization
echo "Step 2/4: Syncing files to $DOCKER_ROOT..."
sudo rsync -av "$TEMP_RESTORE/" "$DOCKER_ROOT/"

# 6. Database Injection
echo "Step 3/4: Restoring MariaDB database..."
if [ -f "$DB_EXPORT_PATH" ]; then
    if docker ps | grep -q "nextcloud-db"; then
        docker exec -i nextcloud-db mariadb -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud < "$DB_EXPORT_PATH"
        echo "[OK] Database successfully imported."
    else
        echo "[WARNING] MariaDB container is not running. Start the stack first and run this script again for DB injection."
    fi
else
    echo "[SKIP] No SQL dump found in the backup archive."
fi

# 7. Permission Correction
echo "Step 4/4: Correcting file permissions..."
sudo chown -R "$USER:$USER" "$DOCKER_ROOT"

if [ -d "${DOCKER_ROOT}/nextcloud/data" ]; then
    sudo chown -R 33:33 "${DOCKER_ROOT}/nextcloud/data"
fi

# 8. Cleanup
echo "Cleaning up temporary files..."
rm -rf "$TEMP_RESTORE"

echo "---"
echo "SUCCESS: Recovery procedure complete."
echo "Note: You might need to restart the stack: docker compose up -d"
