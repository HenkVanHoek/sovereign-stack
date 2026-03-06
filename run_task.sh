#!/bin/bash
# File: run_task.sh
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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).

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
