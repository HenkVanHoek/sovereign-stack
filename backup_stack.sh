#!/bin/bash
# File: backup_stack.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# sovereign-stack Selective Backup Pipeline v3.5
set -u

# Load Environment Dynamically
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"
# Prevent running as root/sudo to protect SSH identity and environment context [cite: 2026-01-22]
if [[ $EUID -eq 0 ]]; then
    echo "---------------------------------------------------------------------"
    echo "[ERROR] This script should NOT be run with sudo or as root."
    echo "Reasoning:"
    echo "1. SSH/SFTP uses your local keys (~/.ssh/id_rsa). Root has different keys."
    echo "2. Environment variables like \$USER and \$DOCKER_ROOT change under sudo."
    echo "---------------------------------------------------------------------"
    echo "If you need Docker permissions, run: sudo usermod -aG docker \$USER"
    echo "Then relog and run this script as: ./backup_stack.sh"
    exit 1
fi
fatal_error() {
    local msg="$1"
    echo "$(date): FATAL - $msg"
    if [ -n "${BACKUP_EMAIL:-}" ]; then
        echo "Critical Backup Failure: $msg" | msmtp "${BACKUP_EMAIL}"
    fi
    exit 1
}

if [ -f "$ENV_PATH" ]; then
    set -a
    # shellcheck disable=SC1090
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    fatal_error ".env file not found at $ENV_PATH"
fi

# Path Validation
if [ ! -d "${DOCKER_ROOT:-}" ]; then
    fatal_error "DOCKER_ROOT directory [${DOCKER_ROOT:-}] does not exist."
fi

# Paths & Vars
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="sovereign_stack_${DATE}.tar.gz.enc"
BACKUP_DIR="${DOCKER_ROOT}/backups"
LOG_FILE="${BACKUP_DIR}/cron.log"
DB_EXPORT="${DOCKER_ROOT}/nextcloud/nextcloud_db_export.sql"

mkdir -p "$BACKUP_DIR"

log_message() {
    echo "$(date): $1"
}
exec >> "$LOG_FILE" 2>&1

log_message "--- Backup Routine Started ---"

# 1. Dependency Check
if ! command -v wakeonlan &> /dev/null; then
    log_message "Dependency 'wakeonlan' not found. Installing..."
    (sudo apt-get update && sudo apt-get install -y wakeonlan) 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null
fi

# 2. System Health Check
RAW_TEMP=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
TEMP_INT=${RAW_TEMP%.*}
TEMP_DISPLAY="${RAW_TEMP}'C"
DISK_USAGE=$(df -h "${DOCKER_ROOT}" | awk 'NR==2 {print $5}')

log_message "System Status: Temp=$TEMP_DISPLAY | Disk=$DISK_USAGE"

# 3. Database Export
log_message "Exporting Nextcloud Database..."
docker exec nextcloud-db mariadb-dump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" \
    nextcloud > "$DB_EXPORT" 2>> "$LOG_FILE"

# 4. Build Dynamic Excludes
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

# 5. Archive & Encrypt
log_message "Archiving and Encrypting..."
sudo tar "${EXCLUDES[@]}" -cvzf - -C "$DOCKER_ROOT" . 2>> "$LOG_FILE" | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$BACKUP_PASSWORD" \
    -out "${BACKUP_DIR}/${FILENAME}" 2>> "$LOG_FILE"

# 6. Remote Wake-up Logic
if [ -n "${PC_MAC:-}" ] && [ -n "${PC_IP:-}" ]; then
    log_message "Sending Wake-on-LAN Magic Packet to ${PC_MAC}..."
    # Fixed SC2024: Use tee -a for sudo-friendly redirection [cite: 2026-01-22]
    wakeonlan "$PC_MAC" 2>&1 | sudo tee -a "$LOG_FILE" > /dev/null

    log_message "Waiting for remote target (${PC_IP}) to respond..."

    MAX_RETRIES=15
    RETRY_COUNT=0
    PC_REACHABLE=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if ping -c 1 -W 1 "$PC_IP" &> /dev/null; then
            log_message "[OK] Target PC is online. Proceeding..."
            PC_REACHABLE=1
            break
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        log_message "Still waiting for ${PC_IP}... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 6
    done

    if [ $PC_REACHABLE -eq 0 ]; then
        log_message "[ERROR] Target PC did not wake up within timeout period."
        # Logic to send alert...
        exit 1
    fi

    sleep 5
fi
# 7. SFTP Transfer
log_message "Transferring to ${BACKUP_TARGET_OS} PC..."
BATCH_FILE=$(mktemp)
REMOTE_PATH="${PC_BACKUP_PATH}"
[[ "$REMOTE_PATH" != /* ]] && REMOTE_PATH="/$REMOTE_PATH"

echo "put ${BACKUP_DIR}/${FILENAME} ${REMOTE_PATH}/" > "$BATCH_FILE"
echo "quit" >> "$BATCH_FILE"

CLEAN_IP=$(echo "$PC_IP" | sed -e 's|^http://||' -e 's|^https://||')
sftp -b "$BATCH_FILE" "${PC_USER}@${CLEAN_IP}" >> "$LOG_FILE" 2>&1
SFTP_STATUS=$?
rm "$BATCH_FILE"

# 8. Local Cleanup
log_message "Cleaning up local archives older than 7 days..."
find "$BACKUP_DIR" -name "sovereign_stack_*.enc" -mtime +7 -delete >> "$LOG_FILE" 2>&1

# 9. Final Status & Email Priority Logic
PRIORITY="Normal"
PRIORITY_HEADER="3"

if [ $SFTP_STATUS -eq 0 ]; then
    STATUS_MSG="SUCCESS: Backup transferred to PC."
    SUBJECT="✅ Sovereign Backup Success ($TEMP_DISPLAY)"
else
    STATUS_MSG="ERROR: Backup transfer FAILED. Check if PC is reachable."
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

# 10. Send Email
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
    sed -n "/--- Backup Routine Started/,/--- Backup Routine Finished/p" "$LOG_FILE" | tail -n 50
    echo "------------------------------------------------------------"
    echo "End of Report."
} > "$TEMP_MAIL"

msmtp "${BACKUP_EMAIL}" < "$TEMP_MAIL"
rm "$TEMP_MAIL"
