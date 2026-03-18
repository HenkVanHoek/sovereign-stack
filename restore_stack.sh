#!/bin/bash
# File: restore_stack.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Restore Script
# ==============================================================================
#
# DESCRIPTION:
# This script restores a previously made backup of the Sovereign Stack.
# It allows you to select from available encrypted archives and restores
# them to the original location.
#
# WHAT IT DOES:
# 1. Lists available encrypted backups from the archive directory
# 2. Prompts user to select which backup to restore
# 3. Decrypts the backup using AES-256-CBC (using DB_PASSWORD from .backup.env)
# 4. Extracts the tar archive to the current directory
# 5. Imports database dumps (if present in backup)
# 6. Corrects file ownership to the current user
#
# IMPORTANT NOTES:
# - This script RESTORES data, not creates a backup!
# - Run from the /home/$USER/docker directory
# - You must have the correct DB_PASSWORD in .backup.env
# - Existing files will be OVERWRITTEN by the restore
#
# DEPENDENCIES:
#    - openssl (for decryption)
#    - tar (for extraction)
#    - docker (for database restore)
#
# CONFIGURATION:
#    See .env for:
#    - BACKUP_LOCAL_TARGET: Location of archive directory
#    - BACKUP_ENCRYPTION_KEY: Password for decryption
#
# USAGE:
#    cd /home/$USER/docker
#    ./restore_stack.sh
#
# IMPORTANT:
#    - Make sure you have a recent backup before testing restore!
#    - Test restore in a development environment first
#    - After restore, verify all services start correctly
#
# ==============================================================================
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
# along with this program.  If not, see https://www.gnu.org/licenses.
# ==============================================================================

# shellcheck disable=SC2154
set -u

# --- 1. Environment & Path Setup ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
else
    echo "[ERROR] .env not found in ${SCRIPT_DIR}"
    exit 1
fi

# Load Version from version.py (Single Source of Truth)
VERSION_FILE="${SCRIPT_DIR}/version.py"
if [[ -f "$VERSION_FILE" ]]; then
    APP_VERSION=$(grep "__version__" "$VERSION_FILE" | sed -E 's/.*["'\'']([^"'\'']+)["'\''].*/\1/')
else
    APP_VERSION="unknown"
fi

ARCHIVE_DIR="${BACKUP_LOCAL_TARGET}/archives"

# --- 2. Identity Guard ---
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo directly."
    exit 1
fi

# --- 3. Selection Logic ---
echo "==========================================================="
echo " Sovereign Stack: Restoration Utility v${APP_VERSION}"
echo "==========================================================="

# FIX: Using find instead of ls for reliability (ShellCheck :52)
echo "Scanning for archives in ${ARCHIVE_DIR}..."
mapfile -t BACKUPS < <(find "${ARCHIVE_DIR}" -maxdepth 1 -name "sovereign_stack_*.enc" -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2- | head -n 5)

if [[ ${#BACKUPS[@]} -eq 0 ]]; then
    echo "[ERROR] No backups found in ${ARCHIVE_DIR}"
    exit 1
fi

echo "Available archives (latest first):"
for i in "${!BACKUPS[@]}"; do
    echo "  [$i] $(basename "${BACKUPS[$i]}")"
done

# FIX: Added -r to read (ShellCheck :64)
read -r -p "Select archive index to restore [0]: " INDEX
INDEX=${INDEX:-0}

SELECTED_BACKUP="${BACKUPS[$INDEX]}"
echo "Selected: $(basename "${SELECTED_BACKUP}")"
echo "-----------------------------------------------------------"

# --- 4. Decryption & Extraction ---
TEMP_TAR="${SCRIPT_DIR}/temp_restored_stack.tar.gz"

echo "[1/4] Decrypting archive (AES-256-CBC)..."
if ! openssl enc -d -aes-256-cbc -salt -pbkdf2 -k "${DB_PASSWORD}" -in "${SELECTED_BACKUP}" -out "${TEMP_TAR}"; then
    echo "[ERROR] Decryption failed. Check DB_PASSWORD in .backup.env"
    exit 1
fi

echo "[2/4] Extracting files to ${SCRIPT_DIR}..."
if ! sudo tar -xzvf "${TEMP_TAR}" -C "${SCRIPT_DIR}"; then
    echo "[ERROR] Extraction failed."
    rm -f "${TEMP_TAR}"
    exit 1
fi

# --- 5. Database Restoration ---
echo "[3/4] Checking for database dumps..."
SQL_DUMP="${SCRIPT_DIR}/all_databases.sql"

if [[ -f "$SQL_DUMP" ]]; then
    echo "Local MariaDB dump found. Starting import..."
    docker compose up -d nextcloud-db
    echo "Waiting for database initialization (15s)..."
    sleep 15

    # FIX: Removed 'cat', using direct redirection (ShellCheck :99)
    if ! docker exec -i nextcloud-db mariadb -u root -p"${DB_PASSWORD}" < "${SQL_DUMP}"; then
        echo "[WARNING] Errors encountered during database import."
    else
        echo "✅ Database restored successfully."
    fi
    sudo rm -f "${SQL_DUMP}"
else
    echo "No database dump found in archive. Skipping."
fi

# --- 6. Finalization & Permissions ---
echo "[4/4] Finalizing restoration and correcting permissions..."
rm -f "${TEMP_TAR}"

# Restore ownership to local user (Sovereign Standard)
sudo chown -R "${USER}:${USER}" "${SCRIPT_DIR}"

echo "==========================================================="
echo "✅ Restoration of $(basename "${SELECTED_BACKUP}") Complete!"
echo "==========================================================="
echo "Next steps:"
echo " 1. Verify your .env files."
echo " 2. Restart the stack: docker compose up -d --force-recreate"
echo "==========================================================="
