#!/bin/bash
# File: clean_stack.sh
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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

set -u
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Identity Guard
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR] This script should NOT be run with sudo or as root.${NC}" >&2
    exit 1
fi

# 2. Sovereign Guard: Locking
exec 300>/tmp/sovereign_clean.lock
if ! flock -n 300; then
    echo "[INFO] Maintenance script is already running."
    exit 0
fi

# 3. Environment Setup
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    # shellcheck source=/dev/null
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
fi

# Mandatory call to verify_env.sh
if ! "${SCRIPT_DIR}/verify_env.sh" > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] Environment verification failed. Check your .env file.${NC}" >&2
    exit 1
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}       Sovereign Stack Maintenance        ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 4. Prune Docker Resources
echo -e "\n${GREEN}[1/4] Cleaning up unused Docker resources...${NC}"
# Removes stopped containers, unused networks, and dangling images
docker system prune -f

# 5. Surgical Permission Fix (v4.3.0 Standard)
echo -e "\n${GREEN}[2/4] Enforcing Surgical Permissions...${NC}"

# Nextcloud Data (UID 33)
if [ -d "${DOCKER_ROOT}/nextcloud/data" ]; then
    echo " -> Fixing Nextcloud Data (UID 33)..."
    sudo chown -R 33:33 "${DOCKER_ROOT}/nextcloud/data"
fi

# MariaDB Nextcloud (UID 999)
if [ -d "${DOCKER_ROOT}/nextcloud/db" ]; then
    echo " -> Fixing Nextcloud Database (UID 999)..."
    sudo chown -R 999:999 "${DOCKER_ROOT}/nextcloud/db"
fi

# MariaDB Forgejo (UID 999)
if [ -d "${DOCKER_ROOT}/forgejo/db" ]; then
    echo " -> Fixing Forgejo Database (UID 999)..."
    sudo chown -R 999:999 "${DOCKER_ROOT}/forgejo/db"
fi

# Forgejo Data (UID 1000)
if [ -d "${DOCKER_ROOT}/forgejo/data" ]; then
    echo " -> Fixing Forgejo Data (UID 1000)..."
    sudo chown -R 1000:1000 "${DOCKER_ROOT}/forgejo/data"
fi

# PostgreSQL NetBox (UID 70)
if [ -d "${DOCKER_ROOT}/netbox/db" ]; then
    echo " -> Fixing NetBox Database (UID 70)..."
    sudo chown -R 70:70 "${DOCKER_ROOT}/netbox/db"
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
UPGRADES=$(apt list --upgradable 2>/dev/null | grep -c -v "Listing...")
if [ "$UPGRADES" -gt 0 ]; then
    echo -e "${BLUE}[INFO] ${UPGRADES} packages can be upgraded. Run 'sudo apt upgrade' manually.${NC}"
else
    echo -e "[OK] System is fully up to date."
fi

echo -e "\n${GREEN}Maintenance Complete.${NC}"
