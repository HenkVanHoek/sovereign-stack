#!/bin/bash
# File: run_task.sh
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - Docker Task Runner
# ==============================================================================
#
# DESCRIPTION:
# Executes a Python script inside a Docker container with the Sovereign Stack
# environment variables mounted. Useful for running maintenance tasks that need
# access to the stack's configuration and network.
#
# WHAT IT DOES:
# 1. Prevents running as root (security guard)
# 2. Verifies .env exists
# 3. Validates script parameter is provided
# 4. Runs specified Python script in python:3.11-slim container with:
#    - Current user/group mapping
#    - Stack network (pi-services)
#    - Mounted .env file
#    - Writable /tmp as HOME
#    - Pre-installed: pynetbox, python-dotenv, PyYAML
#
# EXIT CODES:
# Exit code from the Python script (0 = success)
#
# DEPENDENCIES:
#    - docker
#    - Python script argument
#
# CONFIGURATION:
#    Reads from .env (mounted into container)
#
# USAGE:
#    ./run_task.sh <script.py>
#
#    # Examples:
#    ./run_task.sh infra_scanner.py
#    ./run_task.sh import_inventory.py
#    ./run_task.sh my_custom_script.py
#
# NOTE:
#    The script is mounted at /app inside the container
#    HOME is set to /tmp to allow pip install --user
#
# ==============================================================================

set -u

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
