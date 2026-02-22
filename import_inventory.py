#!/usr/bin/env python3
"""
# ==============================================================================
# Sovereign Stack - NetBox Inventory Importer
#
# This script automates the registration of Docker services into NetBox.
# It extracts service names and images from docker-compose.yaml and
# synchronizes them as Virtual Machines with custom fields.
#
# Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License.
# ==============================================================================
"""

import os
import sys
import fcntl
import subprocess
import yaml
import pynetbox
from datetime import datetime
from dotenv import load_dotenv


def log_message(message):
    """Log timestamped entries."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


def fatal_error(message):
    """Handle critical failures and exit."""
    log_message(f"FATAL ERROR: {message}")
    sys.exit(1)


def check_safety_guards(active_root):
    """Mandatory Sovereign Stack safety checks."""
    # 1. Root Prevention
    if os.geteuid() == 0:
        fatal_error("This script must not be run as root/sudo.")

    # 2. Path Validation
    if not active_root or not os.path.exists(active_root):
        fatal_error(f"Active root path invalid: {active_root}")

    # 3. Pre-flight Check (verify_env.sh)
    if not os.path.exists("verify_env.sh"):
        fatal_error("verify_env.sh not found in current directory.")

    result = subprocess.run(["/bin/bash", "verify_env.sh"], capture_output=True)
    if result.returncode != 0:
        # We log the error output from verify_env.sh for easier debugging
        log_message(f"Verify script output: {result.stderr.decode().strip()}")
        fatal_error("Pre-flight check (verify_env.sh) failed.")


def get_docker_services_with_images(compose_path):
    """Extract service names and images from the compose file."""
    if not os.path.exists(compose_path):
        fatal_error(f"Compose file not found at {compose_path}")

    with open(compose_path, 'r') as f:
        try:
            data = yaml.safe_load(f)
            services_data = data.get('services', {})
            # Create a mapping of service name to its docker image
            return {name: config.get('image', 'unknown') for name, config in
                    services_data.items()}
        except yaml.YAMLError as exc:
            fatal_error(f"Error parsing YAML: {exc}")


def main():
    """Main execution flow for inventory sync."""
    load_dotenv()

    # 4. Anti-Stacking (Flock)
    lock_path = "/tmp/sovereign_netbox_import.lock"
    lock_file = open(lock_path, 'w')
    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        fatal_error("Another instance of this script is already running.")

    # --- Environment & Path Setup ---
    # Detect if running inside Docker container to set correct root path
    if os.path.exists("/.dockerenv"):
        log_message("Docker environment detected. Using /app as root.")
        active_root = "/app"
    else:
        active_root = os.getenv("DOCKER_ROOT", "").strip('"').strip("'")

    check_safety_guards(active_root)

    # Robust loading of NetBox credentials
    nb_url = os.getenv("NETBOX_URL", "").strip('"').strip("'").split(']')[0].strip('[')
    nb_token = os.getenv("NETBOX_API_TOKEN", "").strip('"').strip("'")

    if not nb_url or not nb_token:
        fatal_error("NETBOX_URL or NETBOX_API_TOKEN not set in .env")

    # Initialize NetBox API
    nb = pynetbox.api(nb_url, token=nb_token)
    compose_file = os.path.join(active_root, "docker-compose.yaml")

    log_message(f"Starting NetBox sync from {compose_file}")

    services_dict = get_docker_services_with_images(compose_file)

    # Ensure the target cluster exists in NetBox
    cluster = nb.virtualization.clusters.get(name="Sovereign-Pi-Cluster")
    if not cluster:
        fatal_error(
            "Cluster 'Sovereign-Pi-Cluster' not found. Create it in NetBox GUI first.")

    # 5. Sync Loop
    for service_name, image_name in services_dict.items():
        log_message(f"Syncing service: {service_name} (Image: {image_name})")

        vm_payload = {
            'name': service_name,
            'cluster': cluster.id,
            'status': 'active',
            'custom_fields': {
                'docker_image': image_name
            },
            'comments': f"Automated import from Sovereign Stack on {datetime.now().date()}"
        }

        # Check for existing VM within the specific cluster
        vm = nb.virtualization.virtual_machines.get(name=service_name,
                                                    cluster_id=cluster.id)

        try:
            if vm:
                # Update existing VM entry
                vm.update(vm_payload)
                log_message(f"Successfully updated VM: {service_name}")
            else:
                # Create new VM entry
                nb.virtualization.virtual_machines.create(**vm_payload)
                log_message(f"Successfully created VM: {service_name}")
        except Exception as e:
            log_message(f"Warning: Failed to sync {service_name}. Error: {e}")

    log_message("Inventory synchronization completed successfully.")


if __name__ == "__main__":
    main()
