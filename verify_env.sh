#!/bin/bash
# File: verify_env.sh
# Part of the sovereign-stack project.
# Version: 4.1.0 (Integrity Update)
#
# Copyright (C) 2026 Henk van Hoek
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.

set -u

# 1. Identity Guard
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# 2. Variable Check (Full sync including Netbox)
REQUIRED_VARS=(
    "TZ"
    "DOMAIN"
    "SECOND_DOMAIN"
    "DOCKER_ROOT"
    "INTERNAL_HOST_IP"
    "EXTERNAL_DNS_IP"
    "EXTERNAL_DNS_NAME"
    "FRIGATE_RTSP_PASSWORD"
    "FRIGATE_MQTT_USER"
    "FRIGATE_MQTT_PASSWORD"
    "HA_USER"
    "HA_PASSWORD"
    "HA_MQTT_USER"
    "HA_MQTT_PASSWORD"
    "SMTP_HOST"
    "SMTP_PORT"
    "SMTP_TLS"
    "NPM_CERT_ID"
    "SIGNUPS_ALLOWED"
    "STEP_CA_EMAIL"
    "STEPCA_PASSWORD"
    "STEPCA_PROVISIONER_NAME"
    "STEPCA_PROVISIONER_PASSWORD"
    "STEP_CA_DNS_IP"
    "STEPCAT_FINGERPRINT"
    "BACKUP_EMAIL"
    "BACKUP_PASSWORD"
    "BACKUP_RETENTION_DAYS"
    "BACKUP_TARGET_USER"
    "BACKUP_TARGET_IP"
    "BACKUP_TARGET_PATH"
    "BACKUP_TARGET_MAC"
    "BACKUP_TARGET_OS"
    "BACKUP_MAX_RETRIES"
    "BACKUP_RETRY_WAIT"
    "INCLUDE_FRIGATE_DATA"
    "INCLUDE_NEXTCLOUD_DATA"
    "ICON_BLACKLIST_LOCAL"
    "ICON_DOWNLOAD_TIMEOUT"
    "NEXTCLOUD_MAIL_FROM_ADDRESS"
    "NEXTCLOUD_MAIL_DOMAIN"
    "NEXTCLOUD_MAIL_SMTPHOST"
    "NEXTCLOUD_MAIL_SMTPPORT"
    "NEXTCLOUD_MAIL_SMTPSECURE"
    "NEXTCLOUD_MAIL_SMTPAUTH"
    "NEXTCLOUD_MAIL_SMTPNAME"
    "NEXTCLOUD_MAIL_SMTPPASSWORD"
    "NEXTCLOUD_DB_ROOT_PASSWORD"
    "NEXTCLOUD_DB_PASSWORD"
    "NEXTCLOUD_DB_USER"
    "NEXTCLOUD_DB_NAME"
    "NEXTCLOUD_TRUSTED_DOMAINS"
    "FORGEJO_USER"
    "FORGEJO_DB_USER"
    "FORGEJO_DB_PASSWORD"
    "FORGEJO_DB_NAME"
    "CHAT_NPM_CERT_ID"
    "SIGNAL_CLI_API_PASSWORD"
    "SIGNAL_API_PORT"
    "COTUR_SECRET"
    "NETBOX_API_TOKEN_PEPPERS"
    "NETBOX_SECRET_KEY"
    "NETBOX_DB_NAME"
    "NETBOX_DB_USER"
    "NETBOX_DB_PASSWORD"
    "NETBOX_ALLOWED_HOSTS"
    "NETBOX_URL"
    "NETBOX_API_TOKEN"
)

MISSING=0
# Load .env if it exists in the same directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source <(sed 's/\r$//' "${SCRIPT_DIR}/.env")
    set +a
fi

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "[ERROR] Environment variable $var is not set in .env" >&2
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    echo "[FATAL] Missing $MISSING required variables. Check your .env file." >&2
    exit 1
fi

# 3. Path Guard
if [ ! -f "/.dockerenv" ]; then
    if [ ! -d "${DOCKER_ROOT}" ]; then
        echo "[ERROR] DOCKER_ROOT directory [${DOCKER_ROOT}] does not exist." >&2
        exit 1
    fi
else
    # In container context, we check for /app instead
    if [ ! -d "/app" ]; then
        echo "[ERROR] Internal /app directory does not exist." >&2
        exit 1
    fi
fi

exit 0
