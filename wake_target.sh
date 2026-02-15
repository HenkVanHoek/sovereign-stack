#!/bin/bash
# File: wake_target.sh
# Part of the sovereign-stack project.
# Version: 4.0.0 (Sovereign Awakening)
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
# along with this program.  If not, see https://www.gnu.org/licenses/.

set -u

# 1. Identity Guard (Sectie 2: Root Prevention)
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# 2. Environment Setup & Pre-flight (Sectie 2)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
fi

# Mandatory call to verify_env.sh as per Master Spec
if ! "${SCRIPT_DIR}/verify_env.sh" > /dev/null 2>&1; then
    echo "[ERROR] Environment verification failed. Cannot proceed with WOL." >&2
    exit 1
fi

# 3. Parameter Validation
PC_MAC=${1:-${BACKUP_TARGET_MAC:-}}
TARGET_IP=${2:-${BACKUP_TARGET_IP:-}}
MAX_RETRIES=${3:-15}
RETRY_WAIT=${4:-6}

if [[ -z "$PC_MAC" || -z "$TARGET_IP" ]]; then
    echo "Usage: $0 <MAC_ADDRESS> <IP_ADDRESS> [MAX_RETRIES] [RETRY_WAIT]" >&2
    exit 1
fi

# 4. Dependency Check
if ! command -v wakeonlan &> /dev/null; then
    echo "[ERROR] 'wakeonlan' is not installed. Please install it first." >&2
    exit 1
fi

# 5. Core Logic: Wake-on-LAN Polling Loop (Sectie 3C)
# Send Magic Packet to broadcast address
wakeonlan "$PC_MAC" > /dev/null 2>&1

RETRY_COUNT=0
while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
    # -c 1 (1 ping), -W 1 (1 second timeout)
    if ping -c 1 -W 1 "$TARGET_IP" &> /dev/null; then
        # Buffer for SSH service initialization
        sleep 5
        exit 0
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep "$RETRY_WAIT"
done

# Fail if target remains unreachable
exit 1
