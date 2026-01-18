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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# ... [Stages 1 & 2 remain the same as previous version] ...

# --- STAGE 3: Environment Configuration (.env) ---
echo -e "\n${BLUE}Step 3: Configuring Environment...${NC}"
if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo -e "${YELLOW}Created .env from template.${NC}"
fi

update_var() {
    local var_name=$1
    local current_val=$2
    local prompt_text=$3
    echo -e "\n[REQUIRED] ${BLUE}${prompt_text}${NC}"
    read -p "Value [${current_val:-EMPTY}]: " new_val
    if [ -n "$new_val" ]; then
        # Handle single vs double quotes based on variable name
        if [[ "$var_name" == "FRIGATE_RTSP_PASSWORD" ]]; then
            sed -i "s|^${var_name}=.*|${var_name}='${new_val}'|" "$ENV_FILE"
        else
            sed -i "s|^${var_name}=.*|${var_name}=\"${new_val}\"|" "$ENV_FILE"
        fi
        echo -e "${GREEN}Updated $var_name${NC}"
    fi
}

# The expanded list matching your .env.example
VARS_TO_CHECK=(
    "DOCKER_ROOT|Absolute path to project folder (e.g., /home/hvhoek/docker)"
    "DOMAIN|Primary domain (e.g., piselfhosting.com)"
    "STEP_CA_DNS_IP|Local LAN IP of this Pi (e.g., 192.168.178.118)"
    "BACKUP_EMAIL|Alert/Admin email (Freedom.nl recommended)"
    "BACKUP_PASSWORD|Encryption key for AES-256 backups"
    "PC_USER|Windows workstation username for SFTP"
    "PC_IP|Static IP of your Windows workstation"
    "PC_BACKUP_PATH|Target path on Windows (e.g., /D/SovereignBackups)"
    "NEXTCLOUD_DB_ROOT_PASSWORD|MariaDB Root Password"
    "NEXTCLOUD_DB_PASSWORD|Nextcloud Database User Password"
    "NEXTCLOUD_DOMAIN|Nextcloud FQDN (e.g., cloud.piselfhosting.com)"
    "STEPCA_PASSWORD|Step-CA Root Password"
    "STEPCA_PROVISIONER_PASSWORD|Step-CA Provisioner Password"
    "FRIGATE_RTSP_PASSWORD|CCTV Camera RTSP Password (Single quotes applied)"
    "FRIGATE_MQTT_PASSWORD|MQTT Password for Frigate"
    "HA_PASSWORD|Home Assistant Admin Password"
    "HA_MQTT_PASSWORD|MQTT Password for Home Assistant"
)

for entry in "${VARS_TO_CHECK[@]}"; do
    IFS="|" read -r var_name description <<< "$entry"
    # Extract current value
    current_value=$(grep "^${var_name}=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    
    # Trigger update if empty, placeholder, or example domain
    if [[ -z "$current_value" ]] || [[ "$current_value" == *"<REPLACE_"* ]] || [[ "$current_value" == *"example.com"* ]] || [[ "$current_value" == *"<YOUR_"* ]]; then
        update_var "$var_name" "$current_value" "$description"
    fi
done

# --- STAGE 4: Final Confirmation & Deployment ---
# ... [Stage 4 remains the same] ...
