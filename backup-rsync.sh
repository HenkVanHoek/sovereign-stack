#!/bin/bash
# File: backup-rsync.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Rsync Backup Script (Legacy)
# ==============================================================================
#
# DESCRIPTION:
# Alternative rsync-based backup script that syncs local Docker data and
# remote Synapse VM data to a local USB drive. This is a legacy backup method;
# consider using backup_stack.sh for the full encrypted backup with 3-2-1
# strategy.
#
# WHAT IT DOES:
# 1. Verifies backup USB drive is mounted at /mnt/usb-8tb
# 2. Syncs local Docker data to BACKUP_LOCAL_TARGET/local_pi/
# 3. For each Synapse VM:
#    - Creates database dump via pg_dumpall
#    - Rsyncs Synapse data directory (excluding postgres_data/)
#    - Keeps 7 days of database dumps
# 4. Truncates log file to last 1000 lines
#
# EXCLUDED:
#    - postgres_data/ (database storage)
#    - cache/ directories
#    - .sock files
#
# DEPENDENCIES:
#    - rsync, ssh, sudo
#    - Docker daemon for database dumps
#    - wakeonlan (for remote VMs)
#
# CONFIGURATION:
#    See .env for:
#    - BACKUP_LOCAL_TARGET: USB drive mount point
#    - LOGFILE: Log file location
#    - SOURCE_LOCAL: Source directory (default: DOCKER_ROOT)
#    - SYNAPSE_VMS: Space-separated list of Synapse VM IPs
#    - SYNAPSE_USER: SSH user for Synapse VMs
#    - SYNAPSE_REMOTE_PATH: Path to Synapse data on VM
#    - SSH_KEY_PATH: Path to SSH private key
#
# OUTPUT:
#    - Local sync: BACKUP_LOCAL_TARGET/local_pi/
#    - Remote sync: BACKUP_LOCAL_TARGET/synapse_<VM_IP>/
#    - Database dumps: BACKUP_LOCAL_TARGET/synapse_<VM_IP>/synapse_db_*.sql
#
# USAGE:
#    ./backup-rsync.sh
#
# ==============================================================================

set -u
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

# Fallback for SOURCE_LOCAL if not defined
SOURCE_LOCAL="${SOURCE_LOCAL:-${DOCKER_ROOT:-/home/$USER/docker}}"

VERSION_FILE="${SCRIPT_DIR}/version.py"

if [[ -f "$VERSION_FILE" ]]; then
    APP_VERSION=$(grep "__version__" "$VERSION_FILE" | sed -E 's/.*["'\'']([^"'\'']+)["'\''].*/\1/')
else
    APP_VERSION="unknown"
fi

# --- 2. Functions ---
send_signal() {
    local message="$1"
    curl -s -u "admin:${SIGNAL_PASS}" -X POST "${SIGNAL_URL}" \
         -H "Content-Type: application/json" \
         -d "{\"message\": \"$message\", \"number\": \"$SIGNAL_SENDER\", \"recipients\": [\"$SIGNAL_RECIPIENT\"]}" > /dev/null 2>&1
}

# --- 3. Start Backup Session ---
{
    echo "========================================================================"
    echo "=== Backup Session started at $(date +%H:%M) on $(date +%Y-%m-%d) ==="
    echo "=== Sovereign Stack Version: $APP_VERSION ==="
    echo "========================================================================"
} >> "$LOGFILE"

send_signal "🚀 PiBackup v$APP_VERSION: Session started on $(hostname). Destination: $BACKUP_LOCAL_TARGET"

if ! mountpoint -q "/mnt/usb-8tb"; then
    MSG="❌ CRITICAL: Backup drive not mounted! Session aborted."
    echo "$(date): $MSG" >> "$LOGFILE"
    send_signal "$MSG"
    exit 1
fi

# --- 4. Local Backup ---
    echo "Syncing local data from $SOURCE_LOCAL to $BACKUP_LOCAL_TARGET/local_pi..." >> "$LOGFILE"
    mkdir -p "$BACKUP_LOCAL_TARGET/local_pi"

    if ! sudo rsync -avz --delete --exclude '**/cache/**' --exclude '**/*.sock' \
          "$SOURCE_LOCAL/" "$BACKUP_LOCAL_TARGET/local_pi/" >> "$LOGFILE" 2>&1; then
        RC=$?
        if [[ $RC -ne 23 && $RC -ne 24 ]]; then
            ERR_FOUND=1
            echo "Local rsync failed with exit code $RC" >> "$LOGFILE"
        fi
    fi
# --- 5. Remote Synapse Backup ---
for VM_IP in $SYNAPSE_VMS; do
    echo "Processing VM: $VM_IP" >> "$LOGFILE"
    mkdir -p "$BACKUP_LOCAL_TARGET/synapse_$VM_IP"

    echo "Creating database dump on $VM_IP..." >> "$LOGFILE"
    if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
        "$SYNAPSE_USER@$VM_IP" "docker exec -t -e PGPASSWORD='$DB_PASSWORD' $DB_CONTAINER_NAME pg_dumpall -U $DB_USER > $SYNAPSE_REMOTE_PATH/synapse_db_dump.sql" 2>> "$LOGFILE"; then
        ERR_FOUND=1
        echo "Database dump failed on $VM_IP" >> "$LOGFILE"
    fi

    echo "Syncing files from $VM_IP to $BACKUP_LOCAL_TARGET/synapse_$VM_IP..." >> "$LOGFILE"
    if ! rsync -avz --delete --exclude 'postgres_data/' \
          --rsync-path="sudo rsync" \
          -e "ssh -i \"$SSH_KEY_PATH\" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
          "$SYNAPSE_USER@$VM_IP:$SYNAPSE_REMOTE_PATH/" \
          "$BACKUP_LOCAL_TARGET/synapse_$VM_IP/" >> "$LOGFILE" 2>&1; then
        RC_REMOTE=$?
        if [[ $RC_REMOTE -ne 23 && $RC_REMOTE -ne 24 ]]; then
            ERR_FOUND=1
            echo "Remote rsync failed for $VM_IP (Exit code: $RC_REMOTE)" >> "$LOGFILE"
        fi
    fi
done

# --- 6. Retention Management ---
echo "Cleaning up old logs and dumps..." >> "$LOGFILE"
tail -n 1000 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"

for VM_IP in $SYNAPSE_VMS; do
    DUMP_FILE="$BACKUP_LOCAL_TARGET/synapse_$VM_IP/synapse_db_dump.sql"
    if [[ -f "$DUMP_FILE" ]]; then
        cp "$DUMP_FILE" "$BACKUP_LOCAL_TARGET/synapse_$VM_IP/synapse_db_$(date +%F).sql"
        find "$BACKUP_LOCAL_TARGET/synapse_$VM_IP/" -name "synapse_db_*.sql" -mtime +7 -delete
    fi
done

# --- 7. Completion ---
if [[ $ERR_FOUND -eq 0 ]]; then
    MSG="✅ PiBackup v$APP_VERSION: Completed successfully on $(hostname). Data stored at $BACKUP_LOCAL_TARGET. Check logs at: $LOGFILE"
else
    MSG="⚠️ PiBackup v$APP_VERSION: Completed with errors. Check log immediately: $LOGFILE"
fi

echo "--- $MSG ---" >> "$LOGFILE"
echo "" >> "$LOGFILE"
send_signal "$MSG"
