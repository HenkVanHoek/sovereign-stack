#!/bin/bash
# File: create_users.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Bulk User Creator
# ==============================================================================
#
# DESCRIPTION:
# Bulk-creates Matrix/Synapse user accounts from a CSV file, generates
# secure passwords, and sends welcome emails to new users.
#
# WHAT IT DOES:
# 1. Prevents running as root (security guard)
# 2. Verifies input CSV file exists
# 3. Checks SIGNUPS_ALLOWED is enabled in .env
# 4. For each line in CSV (semicolon-separated: Name;Email):
#    - Generates username (lowercase, spaces become dots)
#    - Generates 12-character secure password
#    - Registers user via Matrix REST API
#    - Sends welcome email with credentials
#    - Pauses 10 seconds between registrations (rate limiting)
#
# INPUT FORMAT:
#    CSV file (semicolon-separated):
#    Name;Email
#    John Doe;john@example.com
#    Jane Smith;jane@example.com
#
# EXIT CODES:
# 0 = Completed
# 1 = Error (no CSV, root execution, etc.)
#
# DEPENDENCIES:
#    - curl (for Matrix API)
#    - openssl (for password generation)
#    - msmtp (for email sending)
#
# CONFIGURATION:
#    See .env for:
#    - DOMAIN: Matrix domain
#    - SIGNUPS_ALLOWED: Must be "true"
#    - BACKUP_EMAIL: Sender address for welcome emails
#
# OUTPUT:
#    - Creates Matrix/Synapse user accounts
#    - Sends welcome email to each new user
#    - Reports success/failure per user
#
# USAGE:
#    # 1. Create CSV file with format: Name;Email
#    echo "John Doe;john@example.com" > nieuwe_leden.csv
#
#    # 2. Ensure SIGNUPS_ALLOWED=true in .env
#
#    # 3. Run the script
#    ./create_users.sh
#
# IMPORTANT:
#    - Rate limiting: 10 second pause between registrations
#    - Useful for Freedom Internet and similar providers
#
# ==============================================================================

set -u
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Environment Setup
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    # shellcheck source=/dev/null
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
fi

# 2. Checks
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR] Do NOT run this script as root or with sudo.${NC}"
    exit 1
fi

if [ ! -f "nieuwe_leden.csv" ]; then
    echo -e "${RED}[ERROR] Input file 'nieuwe_leden.csv' not found.${NC}"
    echo "Create a CSV file with format: Name;Email"
    exit 1
fi

if [[ "${SIGNUPS_ALLOWED:-false}" != "true" ]]; then
    echo -e "${RED}[ERROR] SIGNUPS_ALLOWED is set to false in .env.${NC}"
    echo "Set it to 'true' temporarily to bulk-create users."
    exit 1
fi

MATRIX_HOST="https://matrix.${DOMAIN}"
echo -e "${GREEN}Starting batch processing for: $MATRIX_HOST${NC}"
echo "---------------------------------------------------"

# 3. Loop through CSV (Delimiter is semicolon ';')
while IFS=';' read -r NAME EMAIL || [ -n "$NAME" ]; do
    [[ -z "$NAME" ]] && continue

    USER_ID=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '.' | tr -cd 'a-z0-9.')
    PASSWORD=$(openssl rand -base64 12)

    echo -n "Processing $NAME (@$USER_ID)... "

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"auth\": {\"type\": \"m.login.dummy\"}, \"username\": \"$USER_ID\", \"password\": \"$PASSWORD\"}" \
        "${MATRIX_HOST}/_matrix/client/r0/register")

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}[SUCCESS]${NC}"

        (
            echo "Subject: Welcome to Your Community (Sovereign Stack)"
            echo "To: $EMAIL"
            echo "From: Sovereign Admin <${BACKUP_EMAIL}>"
            echo "MIME-Version: 1.0"
            echo "Content-Type: text/plain; charset=utf-8"
            echo ""
            echo "Dear $NAME,"
            echo ""
            echo "Welcome to our sovereign communication platform."
            echo "Your account has been created. Here are your login details:"
            echo ""
            echo "---------------------------------------------------"
            echo "Server URL:   $MATRIX_HOST"
            echo "Username:     @$USER_ID:${DOMAIN}"
            echo "Password:     $PASSWORD"
            echo "---------------------------------------------------"
            echo ""
            echo "1. Download the 'Element' app (iOS/Android) or visit $MATRIX_HOST in your browser."
            echo "2. Click 'Edit' on the server field and enter: $MATRIX_HOST"
            echo "3. Log in with the credentials above."
            echo ""
            echo "Best regards,"
            echo "Sovereign Stack Admin"
        ) | msmtp "$EMAIL"

        sleep 10

    elif [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 403 ]; then
        echo -e "${RED}[SKIPPED]${NC} (User likely already exists)"
    else
        echo -e "${RED}[ERROR]${NC} API Code: $HTTP_CODE"
    fi

done < "nieuwe_leden.csv"

echo "---------------------------------------------------"
echo "Batch processing complete."
