#!/bin/bash
# File: test_remote_connection.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# sovereign-stack Remote Connectivity Tester v1.0
set -u

# Load Environment Dynamically
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    echo "Error: .env file not found at $ENV_PATH"
    exit 1
fi

# Clean IP address
CLEAN_IP=$(echo "$PC_IP" | sed -e 's|^http://||' -e 's|^https://||')

echo "--- Sovereign Stack: Remote Connection Test ---"
echo "Target: ${PC_USER}@${CLEAN_IP} (${BACKUP_TARGET_OS})"

# 1. Dependency Check
if ! command -v wakeonlan &> /dev/null; then
    echo "[!] wakeonlan not found. Installing..."
    sudo apt-get update && sudo apt-get install -y wakeonlan
else
    echo "[OK] wakeonlan is installed."
fi

# 2. Wake-on-LAN Phase
if [ -n "${PC_MAC:-}" ]; then
    echo "[...] Sending Magic Packet to ${PC_MAC}..."
    wakeonlan "$PC_MAC"
else
    echo "[SKIP] No PC_MAC defined in .env. Skipping WoL."
fi

# 3. Connectivity Loop
echo "[...] Waiting for SSH availability (Max 90 seconds)..."
MAX_RETRIES=18
RETRY_COUNT=0
CONNECTED=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Try to execute a simple 'echo' via SSH with a short timeout
    ssh -o ConnectTimeout=5 -o BatchMode=yes "${PC_USER}@${CLEAN_IP}" "echo Connection Successful" &> /dev/null
    if [ $? -eq 0 ]; then
        CONNECTED=true
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT+1))
    echo "    (Attempt $RETRY_COUNT/$MAX_RETRIES) Host not ready yet. Retrying in 5s..."
    sleep 5
done

# 4. Final Report
echo "------------------------------------------------"
if [ "$CONNECTED" = true ]; then
    echo "SUCCESS: Remote PC is awake and SSH access is verified."
    echo "Your backup pipeline is ready for deployment."
else
    echo "FAILURE: Could not establish SSH connection within 90 seconds."
    echo "Possible issues:"
    echo " 1. PC_MAC is incorrect or WoL is disabled in BIOS."
    echo " 2. PC_IP is incorrect or the workstation is on a different subnet."
    echo " 3. SSH Public Key (~/.ssh/id_ed25519.pub) is not in the remote authorized_keys."
fi
echo "------------------------------------------------"
