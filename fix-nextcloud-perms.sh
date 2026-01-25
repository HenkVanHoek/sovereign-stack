#!/bin/bash
# File: fix-nextcloud-perms.sh
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# sovereign-stack Nextcloud Permission Fixer v2.0
set -u

# 1. Load Environment Dynamically
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source <(sed 's/\r$//' "$ENV_FILE")
    set +a
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# 2. Define Paths
NC_DIR="${DOCKER_ROOT}/nextcloud"
NC_DATA_DIR="${NC_DIR}/data"

echo "--- Sovereign Stack: Nextcloud Permission Fixer ---"

# 3. Validation
if [ ! -d "$NC_DIR" ]; then
    echo "Error: Nextcloud directory not found at $NC_DIR"
    exit 1
fi

# 4. Apply Permissions
echo "Step 1/2: Setting ownership for Nextcloud app files..."
# Standard files are owned by the host user
sudo chown -R "$USER:$USER" "$NC_DIR"

if [ -d "$NC_DATA_DIR" ]; then
    echo "Step 2/2: Setting ownership for Nextcloud data (UID 33/www-data)..."
    # The data directory MUST be owned by the webserver user
    sudo chown -R 33:33 "$NC_DATA_DIR"

    echo "Applying secure directory and file masks..."
    sudo find "$NC_DATA_DIR" -type d -exec chmod 750 {} \;
    sudo find "$NC_DATA_DIR" -type f -exec chmod 640 {} \;
else
    echo "[SKIP] Nextcloud data directory not found. Only app files updated."
fi

echo "---"
echo "SUCCESS: Permissions fixed for Nextcloud."
echo "Recommendation: If problems persist, restart the container: docker compose restart nextcloud-app"
