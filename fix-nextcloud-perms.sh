#!/bin/bash
# File: fix-nextcloud-perms.sh
# ==============================================================================
# Sovereign Stack - Nextcloud Permission Fixer
# ==============================================================================
#
# DESCRIPTION:
# Fixes file ownership and permissions for Nextcloud directories. The web
# server (www-data/UID 33) must own the data directory, while the host user
# should own application files. Incorrect permissions cause sync issues.
#
# WHAT IT DOES:
# 1. Loads configuration from .env
# 2. Validates Nextcloud directory exists
# 3. Sets ownership of entire Nextcloud directory to host user
# 4. Overrides data directory ownership to UID 33 (www-data)
# 5. Applies secure permissions:
#    - Directories: 750 (rwxr-x---)
#    - Files: 640 (rw-r-----)
#
# IMPORTANT:
#    - Nextcloud app files should be owned by host user
#    - Nextcloud data directory MUST be owned by www-data (UID 33)
#    - Running containers may need restart after permission fix
#
# EXIT CODES:
# 0 = Completed
# 1 = Nextcloud directory not found
#
# DEPENDENCIES:
#    - sudo
#    - chown, chmod, find
#
# CONFIGURATION:
#    See .env for:
#    - DOCKER_ROOT: Path to Docker data directory
#
# USAGE:
#    ./fix-nextcloud-perms.sh
#
#    # After running, restart Nextcloud if issues persist:
#    docker compose restart nextcloud-app
#
# ==============================================================================

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
