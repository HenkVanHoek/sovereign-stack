#!/bin/bash
# File: check_docker_socket.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Docker Socket Security Audit
# ==============================================================================

set -u

# --- 1. Environment & Path Setup ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_FILE="${SCRIPT_DIR}/.env"
WHITELIST_FILE="${SCRIPT_DIR}/socket_whitelist.txt"
ALERT_FILE="/tmp/docker_socket_alert.txt"
HOSTNAME=$(hostname)
FOUND_UNAUTHORIZED=false

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
else
    echo "Error: Configuration file not found at $ENV_FILE"
    exit 1
fi

# Load Version from version.py
VERSION_FILE="${SCRIPT_DIR}/version.py"
if [[ -f "$VERSION_FILE" ]]; then
    APP_VERSION=$(grep "__version__" "$VERSION_FILE" | cut -d '"' -f 2)
else
    APP_VERSION="1.0.0"
fi

# --- 2. Functions ---
send_signal() {
    local message="$1"
    # Ontsnap newlines en vreemde tekens voor valide JSON
    local safe_message
    safe_message=$(echo "$message" | python3 -c "import json, sys; print(json.dumps(sys.stdin.read()))")

    curl -s -u "admin:${SIGNAL_PASS}" -X POST "${SIGNAL_URL}" \
         -H "Content-Type: application/json" \
         -d "{\"message\": $safe_message, \"number\": \"$SIGNAL_SENDER\", \"recipients\": [\"$SIGNAL_RECIPIENT\"]}" > /dev/null 2>&1
}

# --- 3. Audit Logic ---
if [[ ! -f "$WHITELIST_FILE" ]]; then
    touch "$WHITELIST_FILE"
fi

DOCKER_TMPL='{{ .Name }} {{ range .Mounts }}{{ if eq .Source "/var/run/docker.sock" }}HAS_SOCKET{{ end }}{{ end }}'
CURRENT_SOCKET_CONTAINERS=$(docker ps -q | xargs docker inspect --format "$DOCKER_TMPL" | grep "HAS_SOCKET" | awk '{print $1}')

> "$ALERT_FILE"

for container in $CURRENT_SOCKET_CONTAINERS; do
    clean_name=$(echo "$container" | sed 's/^\///')

    if ! grep -q "^$clean_name$" "$WHITELIST_FILE"; then
        echo "⚠️ UNAUTHORIZED SOCKET ACCESS: $clean_name" >> "$ALERT_FILE"
        docker inspect --format='Details: {{.Name}} - Image: {{.Config.Image}}' "$clean_name" >> "$ALERT_FILE"
        FOUND_UNAUTHORIZED=true
    fi
done

# --- 4. Reporting ---
if [[ "$FOUND_UNAUTHORIZED" = true ]]; then
    MESSAGE_BODY=$(cat "$ALERT_FILE")

    # 4a. Email versturen via msmtp (zoals in jouw andere scripts)
    (
        echo "Subject: 🛡️ SECURITY ALERT: Docker Socket Breach on $HOSTNAME"
        echo "To: hvh@freedom.nl"
        echo "From: Sovereign Admin <${BACKUP_EMAIL:-hvh@freedom.nl}>"
        echo "MIME-Version: 1.0"
        echo "Content-Type: text/plain; charset=utf-8"
        echo ""
        echo "De volgende ongeautoriseerde Docker Socket mounts zijn gedetecteerd:"
        echo ""
        echo "$MESSAGE_BODY"
        echo ""
        echo "Gegenereerd door Sovereign Audit v$APP_VERSION"
    ) | msmtp "hvh@freedom.nl"

    # 4b. Signal Alert
    send_signal "🛡️ Security Audit v$APP_VERSION op $HOSTNAME:
$MESSAGE_BODY"
fi
