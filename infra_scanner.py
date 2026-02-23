# ==============================================================================
# Sovereign Stack - Infrastructure SSH Scanner
#
# Author: Henk van Hoek
# Version: v4.3.0 - Docker Container Metadata & NetBox Sync
# ==============================================================================

import os
import json
import time
import logging
import paramiko
import pynetbox
import requests
from dotenv import load_dotenv

try:
    from version import __version__
except ImportError:
    __version__ = "4.3.0-dev"

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("InfraScanner")

DRY_RUN = False

load_dotenv()
NETBOX_URL = os.getenv("NETBOX_URL")
NETBOX_TOKEN = os.getenv("NETBOX_API_TOKEN")

nb_client = None
if NETBOX_URL and NETBOX_TOKEN and not DRY_RUN:
    try:
        nb_client = pynetbox.api(NETBOX_URL, token=NETBOX_TOKEN)
        nb_client.http_session.timeout = 10
    except Exception as init_err:
        logger.error(f"NetBox Init Error: {init_err}")


def verify_octoprint_html(ip):
    """Controleert specifiek op de title-tag om Proxy/Frigate te negeren."""
    for port in [80, 5000]:
        try:
            url = f"http://{ip}:{port}"
            response = requests.get(url, timeout=2)
            if response.status_code == 200 and "<title>OctoPrint" in response.text:
                return True
        except:
            continue
    return False


def load_local_config():
    try:
        with open('inventory.json', 'r') as f_inv:
            inv_data = json.load(f_inv)
        with open('credentials.json', 'r') as f_creds:
            creds_data = json.load(f_creds)
        return inv_data, creds_data
    except Exception:
        return None, None


def get_connection_details(host_name, creds_config):
    defaults = creds_config.get('default', {})
    overrides = creds_config.get('overrides', {}).get(host_name, {})
    return {
        "user": overrides.get('ssh_user', defaults.get('ssh_user')),
        "pass": overrides.get('ssh_pass', defaults.get('ssh_pass'))
    }


def scan_host(host_info, auth_creds):
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

        # 1. VirtualBox VMs ophalen
        _, stdout, _ = ssh.exec_command("vboxmanage list vms")
        results["vms"] = [line.split('"')[1] for line in
                          stdout.read().decode().splitlines() if
                          '"' in line and "<inaccessible>" not in line]

        # 2. Docker Containers ophalen met uitgebreide metadata (JSON output)
        docker_cmd = "docker ps --format '{\"name\": \"{{.Names}}\", \"image\": \"{{.Image}}\", \"created\": \"{{.CreatedAt}}\", \"ports\": \"{{.Ports}}\"}'"
        _, stdout, _ = ssh.exec_command(docker_cmd)

        container_list = []
        for line in stdout.read().decode().splitlines():
            try:
                c_data = json.loads(line)
                container_list.append(c_data)
            except json.JSONDecodeError:
                continue

        results["containers"] = container_list
        results["octoprint"] = verify_octoprint_html(ip)

        return results
    except Exception as e:
        logger.warning(f"  [Offline] {name}: {e}")
        return None
    finally:
        ssh.close()


def sync_to_netbox(host_info, scan_results):
    """Synchronizes clusters, VMs, and Containers to the NetBox API."""
    if DRY_RUN or not nb_client:
        return

    name = host_info['name']

    # Mappings to align with your existing NetBox structure
    vb_cluster_map = {
        "lenovo": "Cluster-lenovoVirtualBox",
        "PC-HENK-2024-01": "Cluster-PC-HENK-2024-01"
    }

    docker_cluster_map = {
        "mail": "Cluster-Sovereign-Pi"
    }

    try:
        # --- PART 1: VIRTUALBOX VMS ---
        if scan_results["vms"]:
            # Use mapping, or fallback to Cluster-{name}
            vb_cluster_name = vb_cluster_map.get(name, f"Cluster-{name}")
            vb_cluster = nb_client.virtualization.clusters.get(name=vb_cluster_name)
            vb_type = nb_client.virtualization.cluster_types.get(name="VirtualBox")

            if not vb_type:
                vb_type = nb_client.virtualization.cluster_types.create(
                    name="VirtualBox", slug="virtualbox")
            if not vb_cluster:
                vb_cluster = nb_client.virtualization.clusters.create(
                    name=vb_cluster_name, type=vb_type.id)

            for vm_name in scan_results["vms"]:
                vm_obj = nb_client.virtualization.virtual_machines.get(name=vm_name,
                                                                       cluster_id=vb_cluster.id)
                if not vm_obj:
                    nb_client.virtualization.virtual_machines.create(
                        name=vm_name, cluster=vb_cluster.id, status="active",
                        comments="Auto-discovered VirtualBox VM by infra_scanner.py"
                    )

        # --- PART 2: DOCKER CONTAINERS ---
        if scan_results.get("containers"):
            # Use mapping, or fallback to Docker-{name}
            docker_cluster_name = docker_cluster_map.get(name, f"Docker-{name}")
            docker_cluster = nb_client.virtualization.clusters.get(
                name=docker_cluster_name)
            docker_type = nb_client.virtualization.cluster_types.get(name="Docker")

            if not docker_type:
                docker_type = nb_client.virtualization.cluster_types.create(
                    name="Docker", slug="docker")
            if not docker_cluster:
                docker_cluster = nb_client.virtualization.clusters.create(
                    name=docker_cluster_name, type=docker_type.id)

            for c_data in scan_results["containers"]:
                c_name = c_data.get("name")
                c_image = c_data.get("image", "N/A")
                c_created = c_data.get("created", "N/A")

                # Create a readable Markdown list
                raw_ports = c_data.get("ports", "")
                if raw_ports:
                    ports_list = "\n".join(
                        [f"  - `{p.strip()}`" for p in raw_ports.split(",") if
                         p.strip()])
                    ports_md = f"**Ports:**\n{ports_list}"
                else:
                    ports_md = "**Ports:** *No ports defined*"

                # Markdown formatting for NetBox comments
                markdown_comments = (
                    f"### Docker Container Details\n"
                    f"- **Image:** `{c_image}`\n"
                    f"- **Created on:** {c_created}\n"
                    f"- {ports_md}\n\n"
                    f"*Auto-discovered by Sovereign Stack Infra-Scanner.*"
                )

                vm_obj = nb_client.virtualization.virtual_machines.get(name=c_name,
                                                                       cluster_id=docker_cluster.id)
                if not vm_obj:
                    nb_client.virtualization.virtual_machines.create(
                        name=c_name, cluster=docker_cluster.id, status="active",
                        comments=markdown_comments
                    )
                else:
                    # Update comments if the container exists but data has changed
                    if vm_obj.comments != markdown_comments:
                        vm_obj.update({"comments": markdown_comments})

        logger.info(f"  [NetBox] Sync completed for {name}")
    except Exception as sync_err:
        logger.error(f"  [NetBox Error] Failed to sync {name}: {sync_err}")

def main():
    logger.info(
        f"Sovereign Stack Infra-Scanner starting (Project Version: {__version__})")
    while True:
        inventory_data, credentials_data = load_local_config()
        full_report = {}
        if inventory_data and credentials_data:
            for host in inventory_data['hosts']:
                creds = get_connection_details(host['name'], credentials_data)
                scan_results = scan_host(host, creds)
                if scan_results:
                    full_report[host['name']] = scan_results
                    sync_to_netbox(host, scan_results)

            report_json = json.dumps(full_report, indent=4)
            logger.info(
                "\n" + "*" * 60 + "\nDISCOVERY OUTPUT DATA:\n" + report_json + "\n" + "*" * 60)

        logger.info("Scan cycle completed. Sleeping 1 hour...")
        time.sleep(3600)


if __name__ == "__main__":
    main()
