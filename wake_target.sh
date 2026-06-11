#!/bin/bash
# File: wake_target.sh
# Part of the sovereign-stack project.
# Version: See version.py
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
# ==============================================================================
# Sovereign Stack - Wake-on-LAN Utility
# ==============================================================================
#
# DESCRIPTION:
# Sends a Wake-on-LAN magic packet to a target machine and polls until it
# becomes reachable via ping. Used to wake NAS or other backup targets before
# remote operations.
#
# WHAT IT DOES:
# 1. Validates environment and required parameters
# 2. Sends WoL magic packet via wakeonlan utility
# 3. Polls target IP until it responds to ping
# 4. Waits 5 seconds extra for SSH service initialization
#
# EXIT CODES:
# 0 = Target successfully woken and reachable
# 1 = Target did not respond within retry limit
#
# DEPENDENCIES:
#    - wakeonlan (apt install wakeonlan)
#    - ping (standard)
#    - verify_env.sh (called internally)
#
# CONFIGURATION:
#    Can use defaults from .env or pass parameters:
#    - BACKUP_OFFSITE_MAC: MAC address of target
#    - BACKUP_OFFSITE_IP: IP address of target
#    - BACKUP_OFFSITE_MAX_RETRIES: Number of ping attempts (default: 15)
#    - BACKUP_OFFSITE_RETRY_WAIT: Seconds between retries (default: 6)
#
# USAGE:
#    # Using defaults from .env
#    ./wake_target.sh
#
#    # With explicit parameters
#    ./wake_target.sh <MAC> <IP> [MAX_RETRIES] [RETRY_WAIT]
#
#    # Called by backup scripts before remote operations
#    ./wake_target.sh "${BACKUP_OFFSITE_MAC}" "${BACKUP_OFFSITE_IP}"
#
# ==============================================================================

set -u

# 1. Identity Guard (Section 2: Root Prevention)
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# 2. Environment Setup & Pre-flight
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

# Set USER if not defined (needed for cron)
if [ -z "${USER:-}" ]; then
    USER=$(whoami)
fi

if [ -f "$ENV_PATH" ]; then
    set -a
    # shellcheck source=/dev/null
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
fi

# Mandatory call to verify_env.sh as per Master Spec
if ! "${SCRIPT_DIR}/verify_env.sh" > /dev/null 2>&1; then
    echo "[ERROR] Environment verification failed. Cannot proceed with WOL." >&2
    exit 1
fi

# 3. Parameter Validation
PC_MAC=${1:-${BACKUP_OFFSITE_MAC:-}}
TARGET_IP=${2:-${BACKUP_OFFSITE_IP:-}}
MAX_RETRIES=${3:-${BACKUP_OFFSITE_MAX_RETRIES:-15}}
RETRY_WAIT=${4:-${BACKUP_OFFSITE_RETRY_WAIT:-6}}

if [[ -z "$PC_MAC" || -z "$TARGET_IP" ]]; then
    echo "Usage: $0 <MAC_ADDRESS> <IP_ADDRESS> [MAX_RETRIES] [RETRY_WAIT]" >&2
    exit 1
fi

# 4. Dependency Check
if ! command -v wakeonlan &> /dev/null; then
    echo "[ERROR] 'wakeonlan' is not installed. Please install it first." >&2
    exit 1
fi

# 5. Core Logic: Wake-on-LAN Polling Loop
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
