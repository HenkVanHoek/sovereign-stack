#!/bin/bash
# File: test_remote_connection.sh
# Part of the sovereign-stack project.
# Version: 3.6.2 (Modular & Agnostic)
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.

# shellcheck disable=SC2154
set -u

# 1. Load Environment Dynamically
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    # shellcheck disable=SC1091,SC1090
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
else
    echo "Error: .env file not found at $ENV_PATH"
    exit 1
fi

# Clean IP address (removes protocol prefixes if present)
CLEAN_IP=$(echo "$BACKUP_TARGET_IP" | sed -e 's|^http://||' -e 's|^https://||')

echo "--- Sovereign Stack: Remote Connection Test ---"
echo "Target: ${BACKUP_TARGET_USER}@${CLEAN_IP} (${BACKUP_TARGET_OS})"

# 2. Dependency Check
if ! command -v wakeonlan &> /dev/null; then
    echo "[!] wakeonlan not found. Installing..."
    sudo apt-get update && sudo apt-get install -y wakeonlan
else
    echo "[OK] wakeonlan is installed."
fi

# 3. Remote Wake-up Phase
# Passing arguments to the modular utility to avoid usage errors.
if [ -n "${BACKUP_TARGET_MAC:-}" ]; then
    echo "[...] Attempting to wake backup target..."
    if ! "${SCRIPT_DIR}/wake_target.sh" \
        "$BACKUP_TARGET_MAC" \
        "$CLEAN_IP" \
        "$BACKUP_MAX_RETRIES" \
        "$BACKUP_RETRY_WAIT"; then
        echo "[WARN] Target failed to respond to ping. SSH may fail."
    else
        echo "[OK] Target is online."
    fi
else
    echo "[SKIP] No BACKUP_TARGET_MAC defined in .env. Skipping WoL."
fi

# 4. Connectivity Verification
echo "[...] Verifying SSH access..."

if ssh -o ConnectTimeout=10 -o BatchMode=yes "${BACKUP_TARGET_USER}@${CLEAN_IP}" "echo Connection Successful" &> /dev/null; then
    CONNECTED=true
else
    CONNECTED=false
fi

# 5. Final Report
echo "------------------------------------------------"
if [ "$CONNECTED" = true ]; then
    echo "SUCCESS: Remote target is awake and SSH access is verified."
    echo "Your backup pipeline is ready for deployment."
else
    echo "FAILURE: Could not establish SSH connection."
    echo "Possible issues:"
    echo " 1. BACKUP_TARGET_MAC is incorrect or WoL is disabled in BIOS."
    echo " 2. BACKUP_TARGET_IP is incorrect or firewall is blocking Port 22."
    echo " 3. SSH Public Key is not in the remote authorized_keys file."
fi
echo "------------------------------------------------"
