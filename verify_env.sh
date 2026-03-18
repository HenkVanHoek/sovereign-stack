#!/bin/bash
# File: verify_env.sh
# Part of the sovereign-stack project.
# Version: See version.py
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# ==============================================================================
# Sovereign Stack - Environment Validator
# ==============================================================================
#
# DESCRIPTION:
# Validates that all required environment variables from .env are set and
# that critical paths exist. This script is called by most other scripts
# to ensure a safe execution environment.
#
# WHAT IT DOES:
# 1. Prevents running as root (security guard)
# 2. Loads environment variables from .env file
# 3. Validates ~50 required variables are set and non-empty
# 4. Verifies DOCKER_ROOT directory exists (or /app in container context)
#
# EXIT CODES:
# 0 = All variables valid
# 1 = Missing variables or paths not found
#
# DEPENDENCIES:
#    - .env file in script directory
#
# CONFIGURATION:
#    See .env for all required variables including:
#    - TZ, DOMAIN, DOCKER_ROOT
#    - Backup settings (BACKUP_*)
#    - Database credentials (NEXTCLOUD_*, FORGEJO_*, NETBOX_*)
#    - Service credentials (HA_*, FRIGATE_*)
#
# USAGE:
#    ./verify_env.sh
#    # Returns 0 on success, non-zero on failure
#
#    # Called automatically by other scripts before execution
#    if ! ./verify_env.sh > /dev/null 2>&1; then
#        echo "Environment verification failed"
#        exit 1
#    fi
#
# ==============================================================================

set -u

# 1. Identity Guard
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# 2. Variable Check (Full sync including Netbox, Forgejo and Garage S3)
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
    "BACKUP_ENCRYPTION_KEY"
    "BACKUP_LOCAL_TARGET"
    "BACKUP_LOCAL_RETENTION_DAYS"
    "BACKUP_OFFSITE_IP"
    "BACKUP_OFFSITE_USER"
    "BACKUP_OFFSITE_PASSWORD"
    "BACKUP_OFFSITE_PATH"
    "BACKUP_OFFSITE_OS"
    "BACKUP_OFFSITE_WOL"
    "BACKUP_OFFSITE_MAC"
    "BACKUP_OFFSITE_MAX_RETRIES"
    "BACKUP_OFFSITE_RETRY_WAIT"
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
    "GARAGE_RPC_SECRET"
    "GARAGE_ROOT"
)

MISSING=0
# Load .env if it exists in the same directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Set USER if not defined (needed for cron)
if [ -z "${USER:-}" ]; then
    USER=$(whoami)
fi

if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    # shellcheck source=/dev/null
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
