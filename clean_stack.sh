#!/bin/bash
# File: clean_stack.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Maintenance Script
# ==============================================================================
#
# DESCRIPTION:
# Performs routine maintenance tasks: prunes unused Docker resources, fixes
# container ownership permissions, checks disk usage, and reports available
# OS updates.
#
# WHAT IT DOES:
# 1. Prevents running as root (security guard)
# 2. Acquires process lock to prevent concurrent execution
# 3. Prunes Docker system (stopped containers, unused networks, dangling images)
# 4. Fixes ownership for container data directories:
#    - Nextcloud data (UID 33)
#    - Nextcloud database (UID 999)
#    - Forgejo database (UID 999)
#    - Forgejo data (UID 1000)
#    - NetBox database (UID 70)
# 5. Checks disk usage and warns if above 85%
# 6. Checks for available OS updates
#
# EXIT CODES:
# 0 = Completed (errors are non-fatal)
#
# DEPENDENCIES:
#    - docker
#    - sudo
#    - verify_env.sh (called internally)
#
# CONFIGURATION:
#    See .env for:
#    - DOCKER_ROOT: Path to Docker data directory
#
# OUTPUT:
#    - Docker prune results
#    - Permission fix reports
#    - Disk usage percentage
#    - Count of upgradable packages
#
# USAGE:
#    ./clean_stack.sh
#
# SCHEDULED:
#    Can be run manually or via cron for regular maintenance
#
# ==============================================================================

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

# 2. Process Lock Guard
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
