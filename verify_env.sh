#!/bin/bash
# File: verify_env.sh
# Part of the sovereign-stack project.
# Version: 1.3 (Master Spec Compliant)
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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

set -u

# 1. Identity Guard (Sectie 2: Mandatory for every script)
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# 2. Variable Check
REQUIRED_VARS=(
    "DOCKER_ROOT"
    "BACKUP_PASSWORD"
    "BACKUP_EMAIL"
    "BACKUP_TARGET_IP"
    "BACKUP_TARGET_MAC"
    "BACKUP_TARGET_USER"
    "BACKUP_TARGET_PATH"
    "BACKUP_TARGET_OS"
    "BACKUP_RETENTION_DAYS"
    "NEXTCLOUD_DB_PASSWORD"
    "NEXTCLOUD_MAIL_SMTPNAME"
)

MISSING=0
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "[ERROR] Environment variable $var is not set in .env" >&2
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    exit 1
fi

# 3. Path Guard (Sectie 2: Explicitly verify directory existence)
if [ ! -d "${DOCKER_ROOT}" ]; then
    echo "[ERROR] DOCKER_ROOT directory [${DOCKER_ROOT}] does not exist." >&2
    exit 1
fi

exit 0
