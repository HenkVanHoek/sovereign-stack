#!/bin/bash
# File: clean_stack.sh
# Monthly maintenance utility for the sovereign-stack.
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

set -u
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting Sovereign Stack Maintenance...${NC}"

# 1. Prune Docker (Images, Containers, Networks)
echo -e "\nCleaning up unused Docker resources..."
docker system prune -f

# 2. Check Disk Usage
THRESHOLD=85
CURRENT_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

echo -e "\nDisk Usage Check: ${CURRENT_USAGE}%"
if [ "$CURRENT_USAGE" -gt "$THRESHOLD" ]; then
    echo -e "${RED}[WARNING] Disk usage is above ${THRESHOLD}%. Consider expanding storage or deleting old data.${NC}"
else
    echo -e "[OK] Disk usage is within healthy limits."
fi

# 3. Check for OS Updates (But don't install automatically)
echo -e "\nChecking for system updates..."
sudo apt-get update > /dev/null
UPGRADES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

if [ "$UPGRADES" -gt 0 ]; then
    echo -e "${GREEN}[INFO] There are ${UPGRADES} packages that can be upgraded. Run 'sudo apt upgrade' manually.${NC}"
else
    echo -e "[OK] System is up to date."
fi

echo -e "\n${GREEN}Maintenance Complete.${NC}"
