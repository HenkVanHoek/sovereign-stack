#!/bin/bash
# File: install.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for full license text.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# sovereign-stack Master Installation & Setup Wizard v2.2

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    sovereign-stack Installation Wizard   ${NC}"
echo -e "${BLUE}==========================================${NC}"

# --- STAGE 1: System Dependencies ---
echo -e "\n${BLUE}Step 1: Checking System Dependencies...${NC}"
PACKAGES=("msmtp" "msmtp-mta" "openssl" "curl" "ca-certificates" "ssh")

for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo -e "[${GREEN}OK${NC}] $pkg is installed."
    else
        echo -e "[${RED}MISSING${NC}] $pkg is not installed."
        sudo apt-get update && sudo apt-get install -y "$pkg"
    fi
done

# --- STAGE 2: Environment Configuration Wizard ---
if [ ! -f "$ENV_FILE" ]; then cp "$ENV_EXAMPLE" "$ENV_FILE"; fi

update_var() {
    local var_name=$1
    local prompt_text=$2
    current_val=$(grep "^${var_name}=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    echo -e "\n[REQUIRED] ${BLUE}${prompt_text}${NC}"
    read -p "Value [${current_val:-EMPTY}]: " new_val
    if [ -n "$new_val" ]; then
        # Ensure passwords/strings are quoted for YAML/Env safety
        sed -i "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "$ENV_FILE"
    fi
}

# Core Variables
update_var "DOCKER_ROOT" "Absolute path to project (e.g., /home/hvhoek/docker)"
update_var "BACKUP_EMAIL" "Alert email (Freedom.nl recommended)"
update_var "BACKUP_PASSWORD" "Encryption key for AES-256 backups"
update_var "PC_IP" "Static IP of your Windows Backup PC"

# Granular Backup Toggles
echo -e "\n${BLUE}Step 3: Backup Granularity Settings${NC}"
read -p "Include Frigate Video Data in backups? (true/false) [false]: " frig_toggle
frig_toggle=${frig_toggle:-false}
sed -i "s|^INCLUDE_FRIGATE_DATA=.*|INCLUDE_FRIGATE_DATA=\"${frig_toggle}\"|" "$ENV_FILE"

read -p "Include Nextcloud User Data in backups? (true/false) [true]: " nc_toggle
nc_toggle=${nc_toggle:-true}
sed -i "s|^INCLUDE_NEXTCLOUD_DATA=.*|INCLUDE_NEXTCLOUD_DATA=\"${nc_toggle}\"|" "$ENV_FILE"

# --- STAGE 4: Finalize ---
chmod 600 "$ENV_FILE"
chmod +x *.sh
echo -e "\n${GREEN}Setup complete. Configuration saved to .env${NC}"
