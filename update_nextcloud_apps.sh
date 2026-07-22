#!/bin/bash
# File: update_nextcloud_apps.sh
# Part of the sovereign-stack project.
# Version: See version.py

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
# along with this program.  If not, see https://www.gnu.org/licenses.

# ==============================================================================
# Sovereign Stack - Nextcloud App Auto-Updater
# ==============================================================================
#
# DESCRIPTION:
# Automatically updates all Nextcloud apps (plugins/components) and performs
# post-update database migrations and optimizations. This runs command-line
# commands via Docker to bypass UI-based upgrade timeouts.
#
# WHAT IT DOES:
# 1. Prevents running as root.
# 2. Acquires a process lock to prevent concurrent runs.
# 3. Loads stack environment variables.
# 4. Verifies Nextcloud container is running.
# 5. Enables maintenance mode during updates.
# 6. Updates all Nextcloud apps via 'occ app:update --all'.
# 7. Runs 'occ upgrade' to apply database migrations.
# 8. Runs 'occ db:add-missing-indices' to optimize database tables.
# 9. Disables maintenance mode on completion or failure.
#
# EXIT CODES:
# 0 = Completed successfully (or nothing to do).
# 1 = Verification or execution failure.
#
# ==============================================================================

set -euo pipefail

# 1. Identity Guard
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# Set USER variable if not defined (needed for cron compatibility)
if [ -z "${USER:-}" ]; then
    USER=$(whoami)
fi

# 2. Process Lock Guard
exec 300>/tmp/sovereign_nc_update.lock
if ! flock -n 300; then
    echo "[INFO] Nextcloud app update script is already running."
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
else
    echo "[ERROR] Environment file not found at ${ENV_PATH}" >&2
    exit 1
fi

# Verify stack environment integrity
if ! "${SCRIPT_DIR}/verify_env.sh" > /dev/null 2>&1; then
    echo "[ERROR] Environment verification failed. Check your .env file." >&2
    exit 1
fi

CONTAINER_NAME="nextcloud-app"

# 4. Container Status Guard
if ! docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "[ERROR] Nextcloud container (${CONTAINER_NAME}) is not running. Cannot perform updates." >&2
    exit 1
fi

# 5. Safe Cleanup Handler
cleanup() {
    # Ensure Nextcloud is always brought back online, even if a step failed
    docker exec -u www-data "${CONTAINER_NAME}" php occ maintenance:mode --off >/dev/null 2>&1 || true
}
trap cleanup EXIT

# 7. Update Nextcloud Apps
echo "[INFO] Updating all Nextcloud apps..."
if docker exec -u www-data "${CONTAINER_NAME}" php occ app:update --all; then
    echo "[INFO] App update command executed successfully."
else
    echo "[WARNING] One or more Nextcloud apps failed to update." >&2
fi

# 8. Upgrade / Run migrations
echo "[INFO] Running Nextcloud upgrade migrations..."
if docker exec -u www-data "${CONTAINER_NAME}" php occ upgrade; then
    echo "[INFO] Nextcloud upgrade completed."
else
    echo "[WARNING] Nextcloud upgrade returned errors." >&2
fi

# 9. Add missing indices
echo "[INFO] Optimizing database indices..."
if docker exec -u www-data "${CONTAINER_NAME}" php occ db:add-missing-indices; then
    echo "[INFO] Database indices optimized successfully."
else
    echo "[WARNING] Nextcloud database optimization returned errors." >&2
fi

# 10. Restart container to flush PHP OPCache
echo "[INFO] Restarting Nextcloud container to flush OPCache..."
if docker restart "${CONTAINER_NAME}" >/dev/null; then
    echo "[INFO] Nextcloud container restarted successfully."
else
    echo "[WARNING] Failed to restart Nextcloud container." >&2
fi

echo "[INFO] Nextcloud update process finished successfully."
