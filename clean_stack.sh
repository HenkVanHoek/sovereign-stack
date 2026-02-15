#!/bin/bash
# File: clean_stack.sh
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
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Identity Guard (Sectie 2: Root Prevention)
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR] This script should NOT be run with sudo or as root.${NC}" >&2
    exit 1
fi

# 2. Sovereign Guard: Locking (Sectie 2: Anti-Stacking)
exec 300>/tmp/sovereign_clean.lock
if ! flock -n 300; then
    echo "[INFO] Maintenance script is already running."
    exit 0
fi

# 3. Environment Setup (Sectie 2)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
fi

# Mandatory call to verify_env.sh
if ! "${SCRIPT_DIR}/verify_env.sh" > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] Environment verification failed. Check your .env file.${NC}" >&2
    exit 1
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   Sovereign Stack Maintenance (v4.0)     ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 4. Prune Docker Resources
echo -e "\n${GREEN}[1/4] Cleaning up unused Docker resources...${NC}"
# Removes stopped containers, unused networks, and dangling images
docker system prune -f

# 5. Surgical Permission Fix (v4.0 Standard)
echo -e "\n${GREEN}[2/4] Enforcing Surgical Permissions...${NC}"

# Nextcloud Data (UID 33)
if [ -d "${DOCKER_ROOT}/nextcloud/data" ]; then
    echo " -> Fixing Nextcloud (UID 33)..."
    sudo chown -R 33:33 "${DOCKER_ROOT}/nextcloud/data"
fi

# Matrix/Conduit DB (UID 100)
if [ -d "${DOCKER_ROOT}/matrix/db" ]; then
    echo " -> Fixing Matrix (UID 100)..."
    sudo chown -R 100:100 "${DOCKER_ROOT}/matrix/db"
fi

# MariaDB (UID 999)
if [ -d "${DOCKER_ROOT}/nextcloud/db" ]; then
    echo " -> Fixing Database (UID 999)..."
    sudo chown -R 999:999 "${DOCKER_ROOT}/nextcloud/db"
fi

# 6. Disk Usage Check
echo -e "\n${GREEN}[3/4] Checking Disk Usage...${NC}"
THRESHOLD=85
CURRENT_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

if [ "$CURRENT_USAGE" -gt "$THRESHOLD" ]; then
    echo -e "${RED}[WARNING] Disk usage is at ${CURRENT_USAGE}%. Consider cleaning up.${NC}"
else
    echo -e "[OK] Disk usage is healthy at ${CURRENT_USAGE}%."
fi

# 7. OS Updates Check
echo -e "\n${GREEN}[4/4] Checking for OS Updates...${NC}"
sudo apt-get update > /dev/null
UPGRADES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

if [ "$UPGRADES" -gt 0 ]; then
    echo -e "${BLUE}[INFO] ${UPGRADES} packages can be upgraded. Run 'sudo apt upgrade' manually.${NC}"
else
    echo -e "[OK] System is fully up to date."
fi

echo -e "\n${GREEN}Maintenance Complete.${NC}"
