#!/bin/bash
# Sovereign Certificate Generator for Step-CA v2.4
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

# sovereign-stack Certificate Generator logic

set -u

# 1. Load variables from the central .env file dynamically
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    # Tell ShellCheck to ignore that it cannot follow this dynamic source
    # shellcheck disable=SC1090
    source <(sed 's/\r$//' "$ENV_FILE")
    set +a
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

echo "--- Sovereign Certificate Generator ---"
echo "Base Domain detected: $DOMAIN"

# 2. Collect only the subdomain prefix using raw read
read -r -p "Enter Subdomain prefix (e.g., 'vault' for vault.$DOMAIN): " PREFIX
read -r -p "Enter Duration (e.g., 8760h for 1 year, 87600h for 10 years): " DURATION

# 3. Construct the Full FQDN and filenames
FULL_FQDN="${PREFIX}.${DOMAIN}"
CRT_FILE="${FULL_FQDN}.crt"
KEY_FILE="${FULL_FQDN}.key"

# Pull provisioner name from .env
PROVISIONER="${STEPCA_PROVISIONER_NAME}"

# Determine current host user and group IDs
CURRENT_USER=$(id -u):$(id -g)

echo "Generating certificate for $FULL_FQDN via provisioner $PROVISIONER..."

# 4. Generate certificate inside the container
# 5. Verify success directly in the if-statement
if docker exec -it step-ca step ca certificate "$FULL_FQDN" "$CRT_FILE" "$KEY_FILE" \
    --provisioner "$PROVISIONER" \
    --not-after="$DURATION"; then

    echo "Step 1/3: Certificate successfully generated inside container."

    # 6. Copy files from container to host
    echo "Step 2/3: Copying files to local directory..."
    docker cp step-ca:/home/step/"$CRT_FILE" ./"$CRT_FILE"
    docker cp step-ca:/home/step/"$KEY_FILE" ./"$KEY_FILE"

    # 7. Set ownership and clean up container
    sudo chown "$CURRENT_USER" ./"$CRT_FILE" ./"$KEY_FILE"
    docker exec step-ca rm "/home/step/$CRT_FILE" "/home/step/$KEY_FILE"

    echo "Step 3/3: Cleanup complete."
    echo "---"
    echo "Success! Files created: ./${CRT_FILE} and ./${KEY_FILE}"
    echo "Ownership set to UID:GID $CURRENT_USER"
else
    echo "Error: Failed to generate certificate for $FULL_FQDN."
    exit 1
fi
