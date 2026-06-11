#!/bin/bash
# File: INSTALL.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Installation Wizard
# ==============================================================================
#
# DESCRIPTION:
# Interactive installation wizard that installs system dependencies,
# configures the .env file, sets up SSH key authentication, and configures
# cron automation. Run this script on a fresh system to set up the stack.
#
# WHAT IT DOES:
# 1. Checks and installs system dependencies (msmtp, openssl, curl, etc.)
# 2. Creates .env from .env.example if not present
# 3. Interactive prompts for configuration:
#    - DOCKER_ROOT, DOMAIN
#    - Network/DNS settings
#    - Backup configuration
#    - Off-site target OS and WoL settings
# 4. Generates COTUR_SECRET for Nextcloud Talk
# 5. Creates/ed25519 SSH key if missing
# 6. Copies SSH public key to off-site target
# 7. Configures cron for automated backup (03:00) and monitoring (03:30)
# 8. Sets secure permissions on .env and scripts
#
# DEPENDENCIES:
#    - apt-get (Debian/Ubuntu)
#    - ssh, ssh-copy-id
#    - openssl
#
# CONFIGURATION:
#    Reads from/writes to:
#    - .env.example (template)
#    - .env (configuration)
#    - ~/.ssh/id_ed25519* (SSH keys)
#
# OUTPUT:
#    - Configured .env file
#    - SSH key pair (~/.ssh/id_ed25519*)
#    - Cron entries for backup automation
#
# USAGE:
#    ./INSTALL.sh
#
#    # Run as regular user (not root)
#    # Will prompt for sudo password when installing packages
#
# IMPORTANT:
#    - Run from the sovereign-stack directory
#    - Have off-site backup target credentials ready
#    - Review .env after installation for additional settings
#
# ==============================================================================

set -u
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    sovereign-stack Installation Wizard   ${NC}"
echo -e "${BLUE}    (Version managed in version.py)       ${NC}"
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

# Network & DNS
update_var "INTERNAL_HOST_IP" "Static Internal IP of this Pi (e.g., 192.168.178.118)"
update_var "EXTERNAL_DNS_IP" "External DNS IP (e.g., 91.221.218.218)"
update_var "EXTERNAL_DNS_NAME" "External DNS Hostname (e.g., secure.dns.freedom.nl)"

# Backup Config
update_var "BACKUP_EMAIL" "Alert email for notifications"
update_var "BACKUP_ENCRYPTION_KEY" "Encryption key for AES-256 backups"
update_var "BACKUP_LOCAL_TARGET" "Path to local backup storage (USB drive)"
update_var "BACKUP_LOCAL_RETENTION_DAYS" "How many days to keep local backups"
update_var "BACKUP_OFFSITE_IP" "Static IP of off-site backup target (NAS)"
update_var "BACKUP_OFFSITE_USER" "SSH Username on the off-site backup target"
update_var "BACKUP_OFFSITE_PATH" "Path on off-site target (Windows: /X:/Path, Linux: /home/user/bak)"
update_var "BACKUP_OFFSITE_RETENTION_VERSIONS" "Number of backup versions to keep on off-site"

# Generate COTUR_SECRET if not present
if grep -q "COTUR_SECRET=\"\"" "$ENV_FILE" || ! grep -q "COTUR_SECRET=" "$ENV_FILE"; then
    NEW_SECRET=$(openssl rand -hex 32)
    sed -i "s|^COTUR_SECRET=.*|COTUR_SECRET=\"${NEW_SECRET}\"|" "$ENV_FILE"
    echo -e "\n${GREEN}Generated new COTUR_SECRET for Nextcloud Talk.${NC}"
fi

read -r -p "Off-site Target OS (windows/linux/mac) [linux]: " target_os
target_os=${target_os:-linux}
sed -i "s|^BACKUP_OFFSITE_OS=.*|BACKUP_OFFSITE_OS=\"${target_os,,}\"|" "$ENV_FILE"

read -r -p "Enable Wake-on-LAN for off-site target? (YES/NO) [YES]: " wol_enable
wol_enable=${wol_enable:-YES}
sed -i "s|^BACKUP_OFFSITE_WOL=.*|BACKUP_OFFSITE_WOL=\"${wol_enable^^}\"|" "$ENV_FILE"

read -r -p "MAC address for off-site target (e.g., 00:11:32:A7:3E:11): " wol_mac
if [ -n "$wol_mac" ]; then
    sed -i "s|^BACKUP_OFFSITE_MAC=.*|BACKUP_OFFSITE_MAC=\"${wol_mac}\"|" "$ENV_FILE"
fi

# --- STAGE 3: SSH Key Setup (Modern ed25519) ---
echo -e "\n${BLUE}Step 3: Setting up SSH Key-Based Authentication...${NC}"
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating new ed25519 SSH key..."
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
fi

BACKUP_OFFSITE_IP_CLEAN=$(grep "^BACKUP_OFFSITE_IP=" "$ENV_FILE" | cut -d'"' -f2 | sed -e 's|^http://||' -e 's|^https://||')
BACKUP_OFFSITE_USER_VAL=$(grep "^BACKUP_OFFSITE_USER=" "$ENV_FILE" | cut -d'"' -f2)

echo -e "Copying public key to the off-site target..."
echo -e "Please enter the password for ${BACKUP_OFFSITE_USER_VAL}@${BACKUP_OFFSITE_IP_CLEAN} to enable automation."
ssh-copy-id -i ~/.ssh/id_ed25519.pub -o ConnectTimeout=10 "${BACKUP_OFFSITE_USER_VAL}@${BACKUP_OFFSITE_IP_CLEAN}"

# --- STAGE 4: Cron Automation ---
echo -e "\n${BLUE}Step 4: Configuring Automation (Crontab)...${NC}"
D_ROOT=$(grep "^DOCKER_ROOT=" "$ENV_FILE" | cut -d'"' -f2)

(crontab -l 2>/dev/null | grep -v "backup_stack.sh" | grep -v "monitor_backup.sh" | grep -v "Sovereign Stack Automation"; \
echo "# Sovereign Stack Automation
# 03:00 - Start Backup Pipeline
0 3 * * * ${D_ROOT}/backup_stack.sh

# 03:30 - Start Integrity Check & Monitoring
30 3 * * * ${D_ROOT}/monitor_backup.sh") | crontab -

# --- STAGE 5: Finalize ---
chmod 600 "$ENV_FILE"
chmod +x ./*.sh
echo -e "\n${GREEN}Setup complete! Configuration saved to .env${NC}"
echo -e "${RED}IMPORTANT: Edit .env manually to add your Home Assistant and Frigate passwords!${NC}"
echo -e "1. Backups scheduled for 03:00 daily."
echo -e "2. Monitoring (Dead Man's Switch) scheduled for 03:30 daily."
