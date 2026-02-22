# ==============================================================================
# Sovereign Stack - Infrastructure SSH Scanner
#
# Author: Henk van Hoek
# License: GNU GPL-3.0
# Copyright (c) 2026 Henk van Hoek. All rights reserved.
#
# Version: Integrated with Sovereign Stack Project Version
#
# Purpose:
#   Automated infrastructure discovery for the Sovereign Stack.
#   Scans remote hosts for VirtualBox VMs, Docker containers, and
#   specialized services like OctoPrint to keep NetBox synchronized.
# ==============================================================================

import os
import json
import time
import logging
import paramiko
import pynetbox
from dotenv import load_dotenv

# Import the project-wide version
try:
    from version import __version__
except ImportError:
    __version__ = "development"

# Configure logging for Docker visibility
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("InfraScanner")

# Load environment variables from .env
load_dotenv()
NETBOX_URL = os.getenv("NETBOX_URL")
NETBOX_TOKEN = os.getenv("NETBOX_TOKEN")

# Initialize NetBox API connection globally
nb_client = None
if NETBOX_URL and NETBOX_TOKEN:
    try:
        nb_client = pynetbox.api(NETBOX_URL, token=NETBOX_TOKEN)
    except Exception as init_err:
        logger.error(f"Could not initialize NetBox API: {init_err}")


def load_local_config():
    """Loads inventory (metadata) and credentials (secrets) from JSON files."""
    try:
        with open('inventory.json', 'r') as f_inv:
            inv_data = json.load(f_inv)
        with open('credentials.json', 'r') as f_creds:
            creds_data = json.load(f_creds)
        return inv_data, creds_data
    except FileNotFoundError as file_err:
        logger.error(f"Configuration file not found: {file_err}")
        return None, None
    except json.JSONDecodeError as parse_err:
        logger.error(f"JSON parsing error: {parse_err}")
        return None, None


def get_connection_details(host_name, creds_config):
    """Retrieves SSH credentials with optional host-specific overrides."""
    defaults = creds_config.get('default', {})
    overrides = creds_config.get('overrides', {}).get(host_name, {})
    return {
        "user": overrides.get('ssh_user', defaults.get('ssh_user')),
        "pass": overrides.get('ssh_pass', defaults.get('ssh_pass'))
    }


def format_comment(comment_data):
    """Converts a potential list/array of comments into a single multiline string."""
    if isinstance(comment_data, list):
        return "\n".join(comment_data)
    return str(comment_data)


def scan_host(host_info, auth_creds):
    """Discovers VMs and Docker containers on a remote host via SSH."""
    ip = host_info['ip']
    name = host_info['name']

    results = {"vms": [], "containers": [], "octoprint": False, "online": False}
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        logger.info(f"Connecting to {name} ({ip})...")
        ssh.connect(ip, username=auth_creds['user'], password=auth_creds['pass'],
                    timeout=5)
        results["online"] = True

        # 1. Discover VirtualBox VMs
        _, stdout, _ = ssh.exec_command("vboxmanage list vms")
        results["vms"] = [line.split('"')[1] for line in
                          stdout.read().decode().splitlines() if '"' in line]
        if results["vms"]:
            logger.info(f"  [Found] {len(results['vms'])} VMs on {name}")

        # 2. Discover Docker Containers
        _, stdout, _ = ssh.exec_command("docker ps --format '{{.Names}}'")
        results["containers"] = stdout.read().decode().splitlines()
        if results["containers"]:
            logger.info(f"  [Found] {len(results['containers'])} Containers on {name}")

        # 3. Check for OctoPrint service
        _, stdout, _ = ssh.exec_command(
            "pgrep -f octoprint || systemctl is-active octoprint")
        if stdout.read().decode().strip():
            results["octoprint"] = True
            logger.info(f"  [Found] OctoPrint active on {name}")

        return results
    except Exception as scan_err:
        logger.warning(f"  [Offline] {name} is unreachable: {scan_err}")
        return None
    finally:
        ssh.close()


def sync_to_netbox(host_info, scan_results):
    """Synchronizes scan results to NetBox API."""
    if not nb_client:
        return

    name = host_info['name']
    comment = format_comment(host_info.get('comment', ""))

    try:
        if scan_results["vms"]:
            cluster_name = f"Cluster-{name}"
            cluster = nb_client.virtualization.clusters.get(name=cluster_name)

            c_type = nb_client.virtualization.cluster_types.get(name="VirtualBox")
            if not c_type:
                c_type = nb_client.virtualization.cluster_types.create(
                    name="VirtualBox", slug="virtualbox")

            if not cluster:
                cluster = nb_client.virtualization.clusters.create(
                    name=cluster_name,
                    type=c_type.id,
                    comments=comment
                )
                logger.info(f"  [NetBox] Created cluster {cluster_name}")
            else:
                cluster.comments = comment
                cluster.save()

            for vm_name in scan_results["vms"]:
                vm_obj = nb_client.virtualization.virtual_machines.get(name=vm_name,
                                                                       cluster_id=cluster.id)
                if not vm_obj:
                    nb_client.virtualization.virtual_machines.create(
                        name=vm_name,
                        cluster=cluster.id,
                        status="active",
                        comments="Auto-discovered by infra_scanner.py"
                    )
                    logger.info(f"  [NetBox] Created VM: {vm_name}")

        logger.info(f"  [Success] NetBox sync completed for {name}")

    except Exception as sync_err:
        logger.error(f"  [NetBox Error] Failed to sync {name}: {sync_err}")


def main():
    """Main execution loop for the infrastructure scanner."""
    logger.info(f"Sovereign Stack Infra-Scanner v{__version__} starting...")

    while True:
        inventory_data, credentials_data = load_local_config()

        if inventory_data and credentials_data:
            logger.info(f"Scan cycle started for {len(inventory_data['hosts'])} hosts.")

            for host in inventory_data['hosts']:
                current_creds = get_connection_details(host['name'], credentials_data)
                scan_results = scan_host(host, current_creds)

                if scan_results:
                    sync_to_netbox(host, scan_results)

            logger.info("Scan cycle completed.")
        else:
            logger.error("Skipping cycle due to configuration file issues.")

        logger.info("Waiting 1 hour for the next discovery cycle...")
        time.sleep(3600)


if __name__ == "__main__":
    main()
