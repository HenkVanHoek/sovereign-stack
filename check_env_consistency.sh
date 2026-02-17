#!/bin/bash
# File: check_env_consistency.sh
# Part of the sovereign-stack project.
# Purpose: Verify consistency between .env, .env.example, and verify_env.sh
#
# Version: 1.0.1

# --- GPLv3 Header ---
# Copyright (c) 2026 Henk van Hoek.
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.

set -u

# Use current directory as we don't use a /scripts folder yet
BASE_DIR=$(pwd)
ENV_FILE="${BASE_DIR}/.env"
EXAMPLE_FILE="${BASE_DIR}/.env.example"
VERIFY_SCRIPT="${BASE_DIR}/verify_env.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "--- Sovereign Stack: Environment Consistency Check ---"

# 1. Check if files exist
for f in "$ENV_FILE" "$EXAMPLE_FILE" "$VERIFY_SCRIPT"; do
    if [ ! -f "$f" ]; then
        echo -e "${RED}[ERROR] File not found: $f${NC}"
        exit 1
    fi
done

# 2. Extract variables from .env
# We ignore comments (#) and empty lines
mapfile -t VARS < <(grep -E '^[A-Z0-9_]+=' "$ENV_FILE" | cut -d'=' -f1)

MISSING_EXAMPLE=0
MISSING_VERIFY=0

echo "Checking ${#VARS[@]} variables in ${BASE_DIR}..."
echo "----------------------------------------------------------------------"
printf "%-35s | %-12s | %-12s\n" "Variable Name" ".env.example" "verify_env.sh"
echo "----------------------------------------------------------------------"

for var in "${VARS[@]}"; do
    # Check .env.example
    if grep -q "^${var}=" "$EXAMPLE_FILE"; then
        STATUS_EXAMPLE="${GREEN}OK${NC}"
    else
        STATUS_EXAMPLE="${RED}MISSING${NC}"
        ((MISSING_EXAMPLE++))
    fi

    # Check verify_env.sh (looking for the variable name string)
    if grep -q "$var" "$VERIFY_SCRIPT"; then
        STATUS_VERIFY="${GREEN}OK${NC}"
    else
        STATUS_VERIFY="${YELLOW}NOT VALIDATED${NC}"
        ((MISSING_VERIFY++))
    fi

    printf "%-45s | %-21b | %-21b\n" "$var" "$STATUS_EXAMPLE" "$STATUS_VERIFY"
done

echo "----------------------------------------------------------------------"
echo -e "Summary:"
echo -e "  - Missing in .env.example: ${MISSING_EXAMPLE}"
echo -e "  - Not found in verify_env.sh: ${MISSING_VERIFY}"
echo ""

if [ $MISSING_EXAMPLE -eq 0 ] && [ $MISSING_VERIFY -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] All variables are consistent!${NC}"
else
    echo -e "${YELLOW}[ADVICE] Update your files in PyCharm to ensure full stack integrity.${NC}"
fi
