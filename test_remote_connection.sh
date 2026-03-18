#!/bin/bash
# File: test_remote_connection.sh
# Part of the sovereign-stack project.
# Version: 3.6.2 (Modular & Agnostic)
#
# ==============================================================================
# Sovereign Stack - Remote Connection Tester
# ==============================================================================
#
# DESCRIPTION:
# Tests the complete remote backup pipeline: Wake-on-LAN to wake the target
# machine, then SSH connectivity verification. Useful for diagnosing backup
# infrastructure issues.
#
# WHAT IT DOES:
# 1. Installs wakeonlan if not present
# 2. Attempts to wake the off-site target via WoL
# 3. Verifies SSH connection to the target
# 4. Reports success or failure with troubleshooting tips
#
# EXIT CODES:
# 0 = Connection successful
# 1 = Connection failed
#
# DEPENDENCIES:
#    - wakeonlan (auto-installed if missing)
#    - ssh
#    - wake_target.sh (called internally)
#
# CONFIGURATION:
#    See .env for:
#    - BACKUP_OFFSITE_IP: IP of off-site backup target
#    - BACKUP_OFFSITE_USER: SSH username
#    - BACKUP_OFFSITE_MAC: MAC address for WoL
#    - BACKUP_OFFSITE_MAX_RETRIES: WoL retry attempts
#    - BACKUP_OFFSITE_RETRY_WAIT: Seconds between WoL retries
#
# USAGE:
#    ./test_remote_connection.sh
#
# ==============================================================================

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
CLEAN_IP=$(echo "$BACKUP_OFFSITE_IP" | sed -e 's|^http://||' -e 's|^https://||')

echo "--- Sovereign Stack: Remote Connection Test ---"
echo "Target: ${BACKUP_OFFSITE_USER}@${CLEAN_IP} (${BACKUP_OFFSITE_OS})"

# 2. Dependency Check
if ! command -v wakeonlan &> /dev/null; then
    echo "[!] wakeonlan not found. Installing..."
    sudo apt-get update && sudo apt-get install -y wakeonlan
else
    echo "[OK] wakeonlan is installed."
fi

# 3. Remote Wake-up Phase
# Passing arguments to the modular utility to avoid usage errors.
if [ -n "${BACKUP_OFFSITE_MAC:-}" ]; then
    echo "[...] Attempting to wake backup target..."
    if ! "${SCRIPT_DIR}/wake_target.sh" \
        "$BACKUP_OFFSITE_MAC" \
        "$CLEAN_IP" \
        "${BACKUP_OFFSITE_MAX_RETRIES:-15}" \
        "${BACKUP_OFFSITE_RETRY_WAIT:-6}"; then
        echo "[WARN] Target failed to respond to ping. SSH may fail."
    else
        echo "[OK] Target is online."
    fi
else
    echo "[SKIP] No BACKUP_OFFSITE_MAC defined in .env. Skipping WoL."
fi

# 4. Connectivity Verification
echo "[...] Verifying SSH access..."

if ssh -o ConnectTimeout=10 -o BatchMode=yes "${BACKUP_OFFSITE_USER}@${CLEAN_IP}" "echo Connection Successful" &> /dev/null; then
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
    echo " 1. BACKUP_OFFSITE_MAC is incorrect or WoL is disabled in BIOS."
    echo " 2. BACKUP_OFFSITE_IP is incorrect or firewall is blocking Port 22."
    echo " 3. SSH Public Key is not in the remote authorized_keys file."
fi
echo "------------------------------------------------"
