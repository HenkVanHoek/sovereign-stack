#!/bin/bash
# File: create_users.sh
# Part of the sovereign-stack project.
# Version: 4.0.0 (Sovereign Awakening)
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


set -u
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Environment Setup
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="${SCRIPT_DIR}/.env"

if [ -f "$ENV_PATH" ]; then
    set -a
    source <(sed 's/\r$//' "$ENV_PATH")
    set +a
fi

# 2. Checks
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[ERROR] Draai dit script NIET als root/sudo.${NC}"
    exit 1
fi

if [ ! -f "nieuwe_leden.csv" ]; then
    echo -e "${RED}[ERROR] Bestand 'nieuwe_leden.csv' niet gevonden.${NC}"
    echo "Maak een bestand met formaat: Naam;Emailadres"
    exit 1
fi

# Check of registratie open staat
if [[ "${SIGNUPS_ALLOWED:-false}" != "true" ]]; then
    echo -e "${RED}[ERROR] SIGNUPS_ALLOWED staat op false in .env.${NC}"
    echo "Zet dit tijdelijk op true om bulk-gebruikers aan te maken."
    exit 1
fi

MATRIX_HOST="https://matrix.${DOMAIN}"
echo -e "${GREEN}Start batch verwerking voor: $MATRIX_HOST${NC}"
echo "---------------------------------------------------"

# 3. Loop door CSV (Scheidingsteken is puntkomma ';')
while IFS=';' read -r NAAM EMAIL || [ -n "$NAAM" ]; do
    # Sla lege regels over
    [[ -z "$NAAM" ]] && continue

    # A. Genereer Gebruikersnaam (kleine letters, spaties worden punten)
    # Voorbeeld: "Rudi van de Wel" -> "rudi.van.de.wel"
    USER_ID=$(echo "$NAAM" | tr '[:upper:]' '[:lower:]' | tr ' ' '.' | tr -cd 'a-z0-9.')

    # B. Genereer Veilig Wachtwoord (12 tekens)
    PASSWORD=$(openssl rand -base64 12)

    echo -n "Bezig met $NAAM (@$USER_ID)... "

    # C. API Call naar Matrix (Register)
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"auth\": {\"type\": \"m.login.dummy\"}, \"username\": \"$USER_ID\", \"password\": \"$PASSWORD\"}" \
        "${MATRIX_HOST}/_matrix/client/r0/register")

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}[GELUKT]${NC}"

        # D. Stuur Welkomstmail
        (
            echo "Subject: Welkom bij Liberale Vrienden (Sovereign Stack)"
            echo "To: $EMAIL"
            echo "From: Sovereign Admin <${BACKUP_EMAIL}>"
            echo "MIME-Version: 1.0"
            echo "Content-Type: text/plain; charset=utf-8"
            echo ""
            echo "Beste $NAAM,"
            echo ""
            echo "Welkom op ons eigen, soevereine communicatieplatform."
            echo "Je account is aangemaakt. Hier zijn je inloggegevens:"
            echo ""
            echo "---------------------------------------------------"
            echo "Server URL:   $MATRIX_HOST"
            echo "Gebruikersnaam: @$USER_ID:${DOMAIN}"
            echo "Wachtwoord:   $PASSWORD"
            echo "---------------------------------------------------"
            echo ""
            echo "1. Download de app 'Element' (iOS/Android) of ga naar $MATRIX_HOST op je PC."
            echo "2. Kies 'Bewerk' bij server en vul in: $MATRIX_HOST"
            echo "3. Log in met bovenstaande gegevens."
            echo ""
            echo "Met vriendelijke groet,"
            echo "Henk van Hoek"
        ) | msmtp "$EMAIL"

        # E. Anti-Spam Pauze (belangrijk voor Freedom Internet limieten)
        sleep 10

    elif [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 403 ]; then
        echo -e "${RED}[MISLUKT]${NC} (Gebruiker bestaat waarschijnlijk al)"
    else
        echo -e "${RED}[FOUT]${NC} API Code: $HTTP_CODE"
    fi

done < "nieuwe_leden.csv"

echo "---------------------------------------------------"
echo "Klaar."
