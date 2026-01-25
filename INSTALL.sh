#!/bin/bash
# File: INSTALL.sh
# Part of the sovereign-stack project.
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

# sovereign-stack Master Installation & Setup Wizard v3.6.1

set -u
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
PACKAGES=("msmtp" "msmtp-mta" "openssl" "curl" "ca-certificates" "ssh" "cron" "wakeonlan")

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
    read -r -p "Value [${current_val:-EMPTY}]: " new_val
    if [ -n "$new_val" ]; then
        sed -i "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "$ENV_FILE"
    fi
}

update_var "DOCKER_ROOT" "Absolute path to project (e.g., /home/${USER}/sovereign-stack)"
update_var "DOMAIN" "Your primary domain (e.g., example.com)"
update_var "BACKUP_EMAIL" "Alert email for notifications"
update_var "BACKUP_PASSWORD" "Encryption key for AES-256 backups"
update_var "BACKUP_RETENTION_DAYS" "How many days to keep local backups on NVMe"
update_var "BACKUP_TARGET_IP" "Static IP of your Backup Target machine"
update_var "BACKUP_TARGET_USER" "SSH Username on the Backup Target"
update_var "BACKUP_TARGET_PATH" "Path on Target (Windows: /X:/Path, Linux: /home/user/bak)"

# Generate COTUR_SECRET if not present
if grep -q "COTUR_SECRET=\"\"" "$ENV_FILE" || ! grep -q "COTUR_SECRET=" "$ENV_FILE"; then
    NEW_SECRET=$(openssl rand -hex 32)
    sed -i "s|^COTUR_SECRET=.*|COTUR_SECRET=\"${NEW_SECRET}\"|" "$ENV_FILE"
    echo -e "\n${GREEN}Generated new COTUR_SECRET for Nextcloud Talk.${NC}"
fi

read -r -p "Backup Target OS (windows/linux/mac) [windows]: " target_os
target_os=${target_os:-windows}
sed -i "s|^BACKUP_TARGET_OS=.*|BACKUP_TARGET_OS=\"${target_os,,}\"|" "$ENV_FILE"

# --- STAGE 3: SSH Key Setup (Modern ed25519) ---
echo -e "\n${BLUE}Step 3: Setting up SSH Key-Based Authentication...${NC}"
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating new ed25519 SSH key..."
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
fi

BACKUP_TARGET_IP_CLEAN=$(grep "^BACKUP_TARGET_IP=" "$ENV_FILE" | cut -d'"' -f2 | sed -e 's|^http://||' -e 's|^https://||')
BACKUP_TARGET_USER_VAL=$(grep "^BACKUP_TARGET_USER=" "$ENV_FILE" | cut -d'"' -f2)

echo -e "Copying public key to the target..."
echo -e "Please enter the password for ${BACKUP_TARGET_USER_VAL}@${BACKUP_TARGET_IP_CLEAN} to enable automation."
ssh-copy-id -i ~/.ssh/id_ed25519.pub -o ConnectTimeout=10 "${BACKUP_TARGET_USER_VAL}@${BACKUP_TARGET_IP_CLEAN}"

# --- STAGE 4: Cron Automation (v3.6.1 Timing) ---
echo -e "\n${BLUE}Step 4: Configuring Automation (Crontab)...${NC}"
D_ROOT=$(grep "^DOCKER_ROOT=" "$ENV_FILE" | cut -d'"' -f2)

(crontab -l 2>/dev/null | grep -v "backup_stack.sh" | grep -v "monitor_backup.sh" | grep -v "Sovereign Stack Automatisering"; \
echo "# Sovereign Stack Automation v3.6.1
# 03:00 - Start Backup Pipeline
0 3 * * * ${D_ROOT}/backup_stack.sh

# 03:30 - Start Integrity Check & Monitoring
30 3 * * * ${D_ROOT}/monitor_backup.sh") | crontab -

# --- STAGE 5: Finalize ---
chmod 600 "$ENV_FILE"
chmod +x ./*.sh
echo -e "\n${GREEN}Setup complete! Configuration saved to .env${NC}"
echo -e "1. Backups scheduled for 03:00 daily."
echo -e "2. Monitoring (Dead Man's Switch) scheduled for 03:30 daily."
