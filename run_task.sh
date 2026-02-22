#!/bin/bash
# ==============================================================================
# Sovereign Stack - Docker Python Task Runner (Fixed Permissions)
#
# This script executes Python tasks inside a controlled Docker container.
# It maps the host user and sets a writable HOME directory for pip.
#
# Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License.
# ==============================================================================

# --- Safety Guards ---
# Check if run as root on host
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script must not be run as root on the host."
    exit 1
fi

# Check for environment file
if [ ! -f .env ]; then
    echo "Error: .env file not found."
    exit 1
fi

SCRIPT_TO_RUN=$1
if [ -z "$SCRIPT_TO_RUN" ]; then
    echo "Usage: ./run_task.sh <python_script.py>"
    exit 1
fi

echo "Launching $SCRIPT_TO_RUN inside Sovereign Stack environment..."

# --- Execute in Docker with User Mapping and Writable HOME ---
# We set HOME=/tmp so 'pip install --user' has write access.
docker run -it --rm \
    --name sovereign-task-runner \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    --network pi-services \
    -v "$(pwd)":/app \
    -w /app \
    --env-file .env \
    python:3.11-slim \
    sh -c "pip install --user --no-cache-dir pynetbox python-dotenv PyYAML && python3 $SCRIPT_TO_RUN"
