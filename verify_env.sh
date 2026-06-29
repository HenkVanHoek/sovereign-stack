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
# that critical paths exist. This script uses a decoupled YAML file to
# manage the list of required variables.
#
# WHAT IT DOES:
# 1. Prevents running as root (security guard)
# 2. Loads environment variables from .env file (with CRLF protection)
# 3. Validates required variables against required_vars.yaml
# 4. Verifies DOCKER_ROOT directory exists (or /app in container context)
#
# EXIT CODES:
# 0 = All variables valid
# 1 = Missing variables or paths not found
#
# DEPENDENCIES:
#    - .env file in script directory
#    - required_vars.yaml in script directory
#    - yq (YAML processor)
#
# USAGE:
#    ./verify_env.sh
#
# ==============================================================================

set -u

# 1. Identity Guard
if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] This script should NOT be run with sudo or as root." >&2
    exit 1
fi

# Set USER if not defined (needed for cron)
if [ -z "${USER:-}" ]; then
    USER=$(whoami)
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
YAML_FILE="${SCRIPT_DIR}/required_vars.yaml"
ENV_FILE="${SCRIPT_DIR}/.env"

# Check of yq aanwezig is
if ! command -v yq &> /dev/null; then
    echo "[ERROR] 'yq' is niet geïnstalleerd. Installeer met: sudo apt install yq" >&2
    exit 1
fi

# 2. Load .env (with CRLF/Windows line ending protection)
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck source=/dev/null
    source <(sed 's/\r$//' "$ENV_FILE")
    set +a
else
    echo "[ERROR] Configuration file .env not found at $SCRIPT_DIR" >&2
    exit 1
fi

# 3. Variable Validation (via YAML - Python yq compatibility)
MISSING=0
if [ ! -f "$YAML_FILE" ]; then
    echo "[ERROR] Required variables definition file not found: $YAML_FILE" >&2
    exit 1
fi

# Haal alle lijst-items uit de YAML (Python yq syntax: '.[] | .[]')
mapfile -t REQUIRED_VARS < <(yq -r '.[] | .[]' "$YAML_FILE" 2>/dev/null)

# Extra safety check: stop if list is empty
if [ ${#REQUIRED_VARS[@]} -eq 0 ]; then
    echo "[ERROR] No variables found in $YAML_FILE. Check YAML structure." >&2
    exit 1
fi

for var in "${REQUIRED_VARS[@]}"; do
    [[ -z "$var" || "$var" == "null" || "$var" == "---" ]] && continue
    if [ -z "${!var:-}" ]; then
        echo "[ERROR] Environment variable $var is not set in .env" >&2
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    echo "[FATAL] Missing $MISSING required variables. Check your .env file." >&2
    exit 1
fi

# 3b. Verify .env.example parity (Optional but recommended)
EXAMPLE_FILE="${SCRIPT_DIR}/.env.example"
if [ -f "$EXAMPLE_FILE" ]; then
    for var in "${REQUIRED_VARS[@]}"; do
        [[ -z "$var" || "$var" == "null" || "$var" == "---" ]] && continue
        if ! grep -q "^${var}=" "$EXAMPLE_FILE" && ! grep -q "^# ${var}=" "$EXAMPLE_FILE"; then
            echo "[WARNING] Variable $var is missing from .env.example (Documentation Gap)" >&2
        fi
    done
fi

# 4. Path Guard
if [ ! -f "/.dockerenv" ]; then
    # We draaien op de Host (Pi)
    if [ ! -d "${DOCKER_ROOT:-}" ]; then
        echo "[ERROR] DOCKER_ROOT directory [${DOCKER_ROOT:-NOT_SET}] does not exist." >&2
        exit 1
    fi
else
    # In container context (bijv. CI/CD of specifieke tools) checken we /app
    if [ ! -d "/app" ]; then
        echo "[ERROR] Internal /app directory does not exist." >&2
        exit 1
    fi
fi

exit 0
