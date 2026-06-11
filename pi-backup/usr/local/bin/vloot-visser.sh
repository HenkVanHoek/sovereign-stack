#!/bin/bash
# File: vloot-visser.sh
# Part of the sovereign-stack project.
# Version: See version.py

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
# along with this program.  If not, see https://www.gnu.org/licenses/.

# ==============================================================================
# Sovereign Stack - Fleet Backup (Vloot-Visser)
# ==============================================================================
#
# DESCRIPTION:
# Pull-based backup script for Sovereign Stack / PiSelfhosting mesh nodes.
# Retrieves central database and iterates over fleet nodes to rsync
# configurations and dump local databases. Includes thermal guard,
# error tracking, and notifications (Signal/Email).
#
# USAGE:
# Execute via cron or manually. Requires vloot-visser.env.
# ==============================================================================

# 1. Load Environment
ENV_FILE="/usr/local/etc/vloot-visser.env"
# shellcheck source=/dev/null
source "$ENV_FILE"

# Define SSH options for Cron (No strict host checking, explicit key path)
SSH_KEY="/home/hvhoek/.ssh/id_ed25519"
SSH_OPTS=(-i "$SSH_KEY" -o StrictHostKeyChecking=no)

START_TIME=$(date +%s)
TIMESTAMP=$(date +%Y%m%d_%H%M)
# Temporary log file for this session
SESSION_LOG="/tmp/visser_session_$TIMESTAMP.log"

# --- Functions ---
get_temp() {
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp
    else
        echo "0"
    fi
}

send_signal() {
    local message="$1"
    local safe_msg
    safe_msg=$(echo "$message" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')
    curl -s -X POST "$SIGNAL_API" -H "Content-Type: application/json" \
         -d "{\"message\": $safe_msg, \"number\": \"$SIGNAL_SENDER\", \"recipients\": [\"$SIGNAL_RECIPIENT\"]}"
}

# --- Start Routine ---
START_TEMP=$(get_temp)
{
    echo "===================================================="
    echo "Vloot-Visser Report: $TIMESTAMP"
    echo "Start temperature: ${START_TEMP}°C"
    echo "===================================================="
} > "$SESSION_LOG"

# 2. Thermal Guard (Safety first)
if (( $(echo "$START_TEMP >= 75" | bc -l) )); then
    MSG="❌ ABORTED: Pi too warm (${START_TEMP}°C). Check fan!"
    echo "$MSG" >> "$SESSION_LOG"
    send_signal "$MSG"
    mail -s "CRITICAL: Backup aborted ($HOSTNAME)" "$ADMIN_EMAIL" < "$SESSION_LOG"
    exit 1
fi

# 3. Pull Database & Config (Central Dump)
# Find the container name corresponding to the SOURCE_NODE
DB_CONTAINER_SOURCE=""
for i in "${!MATRIX_NODES[@]}"; do
    if [[ "${MATRIX_NODES[$i]}" == "$SOURCE_NODE" ]]; then
        DB_CONTAINER_SOURCE="${MATRIX_DB_CONTAINERS[$i]}"
    fi
done

# If the source node is not in the fleet list, fall back to the .env value
: "${DB_CONTAINER_SOURCE:=$DB_CONTAINER}"

echo "[$(date +%H:%M:%S)] Start database dump from $DB_CONTAINER_SOURCE on $SOURCE_NODE..." >> "$SESSION_LOG"

# shellcheck disable=SC2029
if ssh "${SSH_OPTS[@]}" -n "$BACKUP_USER@$SOURCE_NODE" "sudo /usr/bin/docker exec $DB_CONTAINER_SOURCE pg_dumpall -U $DB_USER" > "$BACKUP_ROOT/database/full_dump_$TIMESTAMP.sql" 2>> "$SESSION_LOG"; then
    DB_STATUS="✅ Database successful"
    DUMP_SIZE=$(du -sh "$BACKUP_ROOT/database/full_dump_$TIMESTAMP.sql" | awk '{print $1}')
else
    DB_STATUS="❌ Database failed"
    DUMP_SIZE="0MB"
fi

echo "[$(date +%H:%M:%S)] Start rsync of configuration..." >> "$SESSION_LOG"

# Initialize error counter for the fleet
VLOOT_ERRORS=0

# Loop through the fleet nodes
for i in "${!MATRIX_NODES[@]}"; do
    NODE="${MATRIX_NODES[$i]}"
    NAME="${MATRIX_NAMES[$i]}"
    CONF_PATH="${MATRIX_CONF_PATHS[$i]}"
    CONTAINER="${MATRIX_DB_CONTAINERS[$i]}"

    echo "[$(date +%T)] >>> START BACKUP: $NAME ($NODE) <<<" >> "$SESSION_LOG"

    # Ensure target directories exist
    mkdir -p "$DEST_DIR/$NODE" "$LOCAL_BACKUP_BASE/$NODE"

    # 1. Config Backup via Rsync
    echo "[$(date +%T)] [$NAME] Syncing config files..." >> "$SESSION_LOG"
    if rsync -avz --timeout=60 -e "ssh ${SSH_OPTS[*]}" --rsync-path="sudo rsync" \
        "$BACKUP_USER@$NODE:$CONF_PATH" "$DEST_DIR/$NODE/" >> "$SESSION_LOG" 2>&1; then
        echo "[$(date +%T)] [$NAME] Config sync successful." >> "$SESSION_LOG"
    else
        ((VLOOT_ERRORS++))
        echo "[$(date +%T)] ERROR: Rsync failed for $NAME" >> "$SESSION_LOG"
    fi

    # 2. Database Backup via SSH
    echo "[$(date +%T)] [$NAME] Dumping database from container: $CONTAINER..." >> "$SESSION_LOG"

    # Use a variable to capture database dump error outputs
    # shellcheck disable=SC2029
    if DB_ERR_LOG=$(ssh "${SSH_OPTS[@]}" "$BACKUP_USER@$NODE" "sudo /usr/bin/docker exec $CONTAINER pg_dumpall -U synapse" > "$LOCAL_BACKUP_BASE/$NODE/db_dump_$(date +%Y%m%d).sql" 2>&1); then
        echo "[$(date +%T)] [$NAME] Database dump successful." >> "$SESSION_LOG"
    else
        ((VLOOT_ERRORS++))
        echo "[$(date +%T)] ERROR: Database dump failed for $NAME" >> "$SESSION_LOG"
        echo "Detail: $DB_ERR_LOG" >> "$SESSION_LOG"
    fi

    echo "----------------------------------------------------" >> "$SESSION_LOG"
done

# Determine overall status based on central DB and fleet nodes
if [ "$VLOOT_ERRORS" -gt 0 ] && [ "$DB_STATUS" = "❌ Database failed" ]; then
    FINAL_STATUS="❌ CRITICAL (Central DB and fleet errors)"
elif [ "$VLOOT_ERRORS" -gt 0 ]; then
    FINAL_STATUS="⚠️ PARTIALLY FAILED ($VLOOT_ERRORS fleet errors)"
elif [ "$DB_STATUS" = "❌ Database failed" ]; then
    FINAL_STATUS="⚠️ WARNING (Central DB failed, fleet OK)"
else
    FINAL_STATUS="✅ ALL SUCCESSFUL"
fi

# 4. Wrap-up & Statistics
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
FINAL_TEMP=$(get_temp)
FREE_SPACE=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $4}')

REPORT="📦 Backup: $TIMESTAMP
Status: $FINAL_STATUS ($DUMP_SIZE)
Temp: ${START_TEMP}°C -> ${FINAL_TEMP}°C
Duration: ${DURATION}s | Free: $FREE_SPACE"

# 5. Send Notifications
echo -e "\nSummary:\n$REPORT" >> "$SESSION_LOG"
send_signal "$REPORT"

# Email with the complete session log file
{
    echo "From: hvh@freedom.nl"
    echo "To: $ADMIN_EMAIL"
    echo "Subject: $MAIL_SUBJECT - $FINAL_STATUS"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/plain; charset=UTF-8"
    echo "" # Crucial empty line between headers and body
    cat "$SESSION_LOG"
} | msmtp -a default "$ADMIN_EMAIL"

# Append session log to main log file and clean up
cat "$SESSION_LOG" >> "$LOG_FILE"
rm -f "$SESSION_LOG"

# 6. Retention
find "$BACKUP_ROOT/database" -name "*.sql" -mtime +"$RETENTION_DAYS" -delete
