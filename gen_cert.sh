#!/bin/bash
# Sovereign Certificate Generator for Step-CA v2.4 [cite: 2026-01-22]
# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek [cite: 2026-01-21]
# Licensed under the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for full license text. [cite: 2026-01-21]
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. [cite: 2026-01-21]

# sovereign-stack Certificate Generator logic [cite: 2026-01-22]

set -u

# 1. Load variables from the central .env file dynamically [cite: 2026-01-22]
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    # Tell ShellCheck to ignore that it cannot follow this dynamic source [cite: 2026-01-22]
    # shellcheck disable=SC1090
    source <(sed 's/\r$//' "$ENV_FILE")
    set +a
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

echo "--- Sovereign Certificate Generator ---"
echo "Base Domain detected: $DOMAIN"

# 2. Collect only the subdomain prefix using raw read [cite: 2026-01-22]
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
# 5. Verify success directly in the if-statement [cite: 2026-01-22]
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
