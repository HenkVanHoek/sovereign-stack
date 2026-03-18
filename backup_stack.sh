#!/bin/bash
# File: backup_stack.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Backup Script (3-2-1 Strategy)
# ==============================================================================
#
# DESCRIPTION:
# This script creates an encrypted backup of the Sovereign Stack Docker
# environment following the 3-2-1 backup strategy:
#
# 3-2-1 BACKUP STRATEGY:
# - 3 copies of your data (original + 2 backups)
# - 2 different storage media (USB drive + NAS)
# - 1 off-site copy (NAS)
#
# BACKUP LOCATIONS:
# 1. Original data: /home/$USER/docker (Pi)
# 2. Local backup: BACKUP_LOCAL_TARGET/archives (USB drive) - keeps BACKUP_LOCAL_RETENTION_DAYS
# 3. Off-site backup: NAS (latest only)
#
# WHAT IT BACKS UP:
# 1. Remote Synapse VM (via Tailscale VPN):
#    - Database dump from synapse_db container
#    - Synapse data via rsync
#
# 2. Local MariaDB databases:
#    - Nextcloud database
#    - Forgejo database
#    - Any other MariaDB databases in the stack
#
# 3. Docker volumes and configuration:
#    - All Docker data directories (excluding large media files)
#    - Configuration files from /home/$USER/docker
#
# EXCLUDED (to save space and time):
#    - Frigate recordings/clips (stored on NAS)
#    - AdGuard query logs
#    - Cache directories
#    - Log files
#    - Backup archives
#
# OUTPUT:
#    - Local: BACKUP_LOCAL_TARGET/archives (USB drive) - keeps BACKUP_LOCAL_RETENTION_DAYS
#    - Remote: NAS (latest only) - see .env for off-site settings
#    - Filename: sovereign_stack_YYYYMMDD_HHMMSS.tar.gz.enc
#
# DEPENDENCIES:
#    - bc (for temperature checks)
#    - openssl (for encryption)
#    - tar, rsync, ssh, sshpass
#    - Docker daemon
#
# CONFIGURATION:
#    See .env for:
#    - BACKUP_LOCAL_TARGET: Where local backups are stored (USB drive)
#    - BACKUP_ENCRYPTION_KEY: Encryption password
#    - Remote Synapse VM settings
#    - Off-site Backup settings (BACKUP_OFFSITE_*)
#    - Signal notifications
#
# USAGE:
#    ./backup_stack.sh
#
# SCHEDULED:
#    Via cron: 0 1 * * * /home/$USER/docker/backup_stack.sh >> /home/$USER/docker/backups/cron.log 2>&1
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

# Set USER if not defined (needed for cron)
if [ -z "${USER:-}" ]; then
    USER=$(whoami)
fi

# --- 1. Environment & Path Setup ---
START_TIME=$(date +%s)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"
ERR_FOUND=0

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
else
    echo "Error: Configuration file not found at $ENV_FILE"
    exit 1
fi

# Load Version from version.py
VERSION_FILE="${SCRIPT_DIR}/version.py"
APP_VERSION=$(grep "__version__" "$VERSION_FILE" | sed -E 's/.*["'\''^]([^"'\''^]+)["'\''^].*/\1/')

# --- 2. Identity & Lock Guard ---
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo directly."
    exit 1
fi

exec 100>/tmp/sovereign_backup.lock
if ! flock -n 100; then
    exit 0
fi

# --- 3. Functions ---
send_signal() {
    local message="$1"
    curl -s -u "admin:${SIGNAL_PASS}" -X POST "${SIGNAL_URL}" \
         -H "Content-Type: application/json" \
         -d "{\"message\": \"$message\", \"number\": \"$SIGNAL_SENDER\", \"recipients\": [\"$SIGNAL_RECIPIENT\"]}" > /dev/null 2>&1
}

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log_stream() {
    while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $line" >> "$LOGFILE"
    done
}

# --- 4. Thermal & System Health ---
get_temp() {
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp
    else
        echo "0"
    fi
}

CURRENT_TEMP=$(get_temp)
DISK_USAGE=$(df -h "$BACKUP_LOCAL_TARGET" | awk 'NR==2 {print $5}')

# --- 5. Start Session & Safety Check ---
{
    echo "========================================================================"
    echo "=== Sovereign Backup Routine v$APP_VERSION Started ==="
    echo "Date: $(date)"
    echo "Temperature: ${CURRENT_TEMP}°C | Disk Usage Target: $DISK_USAGE"
    echo "========================================================================"
} >> "$LOGFILE"

# Thermal Guard
if (( $(echo "$CURRENT_TEMP >= 80" | bc -l) )); then
    MSG="❌ ABORTED: CPU Temperature too high (${CURRENT_TEMP}°C). Safety shutdown of backup."
    log_message "$MSG"
    send_signal "$MSG"
    exit 1
fi

if [[ ! -d "$BACKUP_LOCAL_TARGET" ]]; then
    MSG="❌ CRITICAL: Target $BACKUP_LOCAL_TARGET not found. Drive not mounted?"
    log_message "$MSG"
    send_signal "$MSG"
    exit 1
fi

send_signal "🚀 PiBackup v$APP_VERSION: Started. Temp: ${CURRENT_TEMP}°C, Disk: $DISK_USAGE"

# --- 6. Pre-Flight Retention & Cleanup ---
log_message "Running pre-flight retention cleanup..."
ARCHIVE_DIR="${BACKUP_LOCAL_TARGET}/archives"
REMOTE_TARGET="${BACKUP_LOCAL_TARGET}/remote_synapse"
mkdir -p "$ARCHIVE_DIR" "$REMOTE_TARGET"

find "$ARCHIVE_DIR" -name "sovereign_stack_*.enc" -mtime +"${BACKUP_LOCAL_RETENTION_DAYS}" -delete
find "$REMOTE_TARGET" -name "*.sql" -mtime +7 -delete

# Recalculate disk usage after cleanup to log the newly freed space
DISK_USAGE=$(df -h "$BACKUP_LOCAL_TARGET" | awk 'NR==2 {print $5}')
log_message "Disk Usage Target after cleanup: $DISK_USAGE"

# --- 7. Remote Synapse VM (Lenovo via Tailscale) ---
log_message "Processing Remote Synapse VM..."

if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    "$SYNAPSE_USER@$SYNAPSE_VMS" "docker exec -t -e PGPASSWORD='$SYNAPSE_DB_PASSWORD' $SYNAPSE_DB_CONTAINER pg_dumpall -U $SYNAPSE_DB_USER > $SYNAPSE_REMOTE_PATH/synapse_db_dump.sql" 2> >(log_stream); then
    log_message "ERROR: Remote Database dump failed."
    ERR_FOUND=1
fi

if ! rsync -avz --delete --exclude 'postgres_data/' --rsync-path="sudo rsync" \
      -e "ssh -i \"$SSH_KEY_PATH\" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
      "$SYNAPSE_USER@$SYNAPSE_VMS:$SYNAPSE_REMOTE_PATH/" \
      "$REMOTE_TARGET/" 2>&1 | log_stream; then
    log_message "ERROR: Remote sync failed."
    ERR_FOUND=1
fi

# --- 8. Local Database Exports ---
log_message "Exporting local MariaDB..."
if ! sudo docker exec nextcloud-db mariadb-dump -u root -p"$NEXTCLOUD_DB_ROOT_PASSWORD" --all-databases | sudo tee "${SCRIPT_DIR}/all_databases.sql" > /dev/null 2> >(log_stream); then
    log_message "WARNING: Local database export failed."
    ERR_FOUND=1
fi

# --- 9. Local Archive & Encryption ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${TIMESTAMP}.tar.gz.enc"
TEMP_ARCHIVE="/tmp/sovereign_stack_${TIMESTAMP}.tar.gz"

log_message "Creating archive (excluding media)..."
EXCLUDES=("--exclude=adguardhome/work/data/querylog.json*" "--exclude=storage/recordings/*" "--exclude=storage/clips/*" "--exclude=storage/exports/*" "--exclude=**/cache/**" "--exclude=**/*.sock" "--exclude=*.log" "--exclude=backups")

# Debug: toon beschikbare schijfruimte
log_message "Available disk space on /tmp: $(df -h /tmp | awk 'NR==2 {print $4}')"
log_message "Available disk space on target: $(df -h "$BACKUP_LOCAL_TARGET" | awk 'NR==2 {print $4}')"

if ! sudo tar "${EXCLUDES[@]}" -czf "$TEMP_ARCHIVE" -C "$SCRIPT_DIR" . 2>&1 | tee -a "$LOGFILE"; then
    log_message "ERROR: Tar compression failed."
    ERR_FOUND=1
fi

log_message "Encrypting archive to 8TB drive..."
if ! openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TEMP_ARCHIVE" -out "${ARCHIVE_DIR}/${FILENAME}" -k "$BACKUP_ENCRYPTION_KEY"; then
    log_message "ERROR: Encryption failed."
    ERR_FOUND=1
fi

# --- 10. Off-site Backup (3-2-1 Strategy) ---
# Copy latest backup to off-site target (NAS) for redundancy
log_message "Syncing backup to off-site target (3-2-1 strategy)..."

# Install sshpass if not available
if ! command -v sshpass &> /dev/null; then
    log_message "Installing sshpass for off-site backup..."
    sudo apt update && sudo apt install -y sshpass
fi

# Wake up off-site target via WoL if enabled
if [ "${BACKUP_OFFSITE_WOL:-YES}" = "YES" ]; then
    log_message "Waking up off-site target via WoL..."
    "${SCRIPT_DIR}/wake_target.sh" \
        "${BACKUP_OFFSITE_MAC}" \
        "${BACKUP_OFFSITE_IP}" \
        "${BACKUP_OFFSITE_MAX_RETRIES:-15}" \
        "${BACKUP_OFFSITE_RETRY_WAIT:-6}"
    log_message "Off-site target is awake."
fi

# First create directory, then copy via SSH
if sshpass -p "$BACKUP_OFFSITE_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    "$BACKUP_OFFSITE_USER@$BACKUP_OFFSITE_IP" "mkdir -p $BACKUP_OFFSITE_PATH"; then
    # Use cat over SSH to copy the file (more reliable than scp with sshpass)
    log_message "Copying backup to off-site target..."
    if cat "${ARCHIVE_DIR}/${FILENAME}" | sshpass -p "$BACKUP_OFFSITE_PASSWORD" ssh -o StrictHostKeyChecking=accept-new \
        "$BACKUP_OFFSITE_USER@$BACKUP_OFFSITE_IP" "cat > $BACKUP_OFFSITE_PATH/${FILENAME}"; then
        log_message "✅ Backup synced to off-site target successfully."

        # Keep only configured number of versions on off-site target
        sshpass -p "$BACKUP_OFFSITE_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
            "$BACKUP_OFFSITE_USER@$BACKUP_OFFSITE_IP" "cd $BACKUP_OFFSITE_PATH && ls -t sovereign_stack_*.enc | tail -n +$((BACKUP_OFFSITE_RETENTION_VERSIONS + 1)) | xargs -r rm"
    else
        log_message "WARNING: Failed to sync backup to off-site target."
        ERR_FOUND=1
    fi
else
    log_message "WARNING: Failed to create NAS backup directory."
    ERR_FOUND=1
fi

sudo rm -f "$TEMP_ARCHIVE"
sudo rm -f "${SCRIPT_DIR}/all_databases.sql"

# --- 11. Final Report ---
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
FINAL_TEMP=$(get_temp)

[[ $ERR_FOUND -eq 0 ]] && STATUS="✅ SUCCESS" || STATUS="⚠️ ERRORS FOUND"

MSG="PiBackup v$APP_VERSION: $STATUS
Duration: $((DURATION / 60))m $((DURATION % 60))s
Temp: ${FINAL_TEMP}°C
Archive: $FILENAME"

log_message "--- $MSG ---"
send_signal "$MSG"
