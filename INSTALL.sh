#!/bin/bash
# File: install.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek [cite: 2026-01-21]
# Licensed under the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for full license text. [cite: 2026-01-21]
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details. [cite: 2026-01-21]

# sovereign-stack Master Installation & Setup Wizard v2.5 [cite: 2026-01-21]

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
# Including dependencies for encryption, mailing, and automation
PACKAGES=("msmtp" "msmtp-mta" "openssl" "curl" "ca-certificates" "ssh" "cron")

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
        # Ensure YAML/Env values are quoted [cite: 2025-11-03]
        sed -i "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "$ENV_FILE"
    fi
}

# Use $USER for generic path examples [cite: 2026-01-21]
update_var "DOCKER_ROOT" "Absolute path to project (e.g., /home/${USER}/docker)"
update_var "BACKUP_EMAIL" "Alert email for notifications"
update_var "BACKUP_PASSWORD" "Encryption key for AES-256 backups"
update_var "PC_IP" "Static IP of your Backup Target machine"
update_var "PC_USER" "SSH Username on the Backup Target"
update_var "PC_BACKUP_PATH" "Path on Target (e.g., C:/Backups)"

read -p "Backup Target OS (windows/linux/mac) [windows]: " target_os
target_os=${target_os:-windows}
sed -i "s|^BACKUP_TARGET_OS=.*|BACKUP_TARGET_OS=\"${target_os,,}\"|" "$ENV_FILE"

# --- STAGE 3: SSH Key Setup ---
# Setup for passwordless cron automation
echo -e "\n${BLUE}Step 3: Setting up SSH Key-Based Authentication...${NC}"
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating new SSH key..."
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

PC_IP_CLEAN=$(grep "^PC_IP=" "$ENV_FILE" | cut -d'"' -f2 | sed -e 's|^http://||' -e 's|^https://||')
PC_USER_VAL=$(grep "^PC_USER=" "$ENV_FILE" | cut -d'"' -f2)

echo -e "Copying public key to the target..."
echo -e "Please enter the password for ${PC_USER_VAL}@${PC_IP_CLEAN} to enable automation."
ssh-copy-id -o ConnectTimeout=10 "${PC_USER_VAL}@${PC_IP_CLEAN}"

# --- STAGE 4: Cron Automation ---
# Schedules backup at 04:00 and monitor at 04:30
echo -e "\n${BLUE}Step 4: Configuring Automation (Crontab)...${NC}"
D_ROOT=$(grep "^DOCKER_ROOT=" "$ENV_FILE" | cut -d'"' -f2)

(crontab -l 2>/dev/null | grep -v "backup_stack.sh" | grep -v "monitor_backup.sh"; echo "00 03 * * * /bin/bash ${D_ROOT}/backup_stack.sh >> ${D_ROOT}/backups/cron.log 2>&1
30 04 * * * /bin/bash ${D_ROOT}/monitor_backup.sh >> ${D_ROOT}/backups/cron.log 2>&1") | crontab -

# --- STAGE 5: Finalize ---
chmod 600 "$ENV_FILE"
chmod +x *.sh [cite: 2026-01-21]
echo -e "\n${GREEN}Setup complete! Configuration saved to .env${NC}"
echo -e "1. Backups scheduled for 04:00 daily."
echo -e "2. Monitoring (Dead Man's Switch) scheduled for 04:30 daily."