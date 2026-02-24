# ==============================================================================
# Sovereign Stack - Infrastructure SSH Scanner
#
# Copyright (c) 2026 Henk van Hoek
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ==============================================================================

import os
import json
import logging
import paramiko
import pynetbox
import requests
import urllib3
from dotenv import load_dotenv

from version import __version__

# Suppress insecure request warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("InfraScanner")

DRY_RUN = False

ENV_PATH = "/app/.env"
if os.path.exists(ENV_PATH):
    logger.info(f"[Init] Loading environment variables from {ENV_PATH}")
    load_dotenv(dotenv_path=ENV_PATH)
else:
    logger.warning(f"[Init] {ENV_PATH} not found. Falling back to defaults.")
    load_dotenv()

NETBOX_URL = os.getenv("NETBOX_URL")
NETBOX_TOKEN = os.getenv("NETBOX_API_TOKEN")

CLUSTER_MAP_ENV = os.getenv("NETBOX_CLUSTER_MAPPING", "").strip('\"\'')
logger.info(f"[Init] Raw NETBOX_CLUSTER_MAPPING loaded: '{CLUSTER_MAP_ENV}'")

CLUSTER_MAPPING = {}
if CLUSTER_MAP_ENV:
    for pair in CLUSTER_MAP_ENV.split(","):
        if ":" in pair:
            ip_val, cl_name = pair.split(":", 1)
            CLUSTER_MAPPING[ip_val.strip()] = cl_name.strip()

logger.info(f"[Init] Parsed CLUSTER_MAPPING dictionary: {CLUSTER_MAPPING}")

nb_client = None
if NETBOX_URL and NETBOX_TOKEN and not DRY_RUN:
    try:
        nb_client = pynetbox.api(NETBOX_URL, token=NETBOX_TOKEN)
        nb_client.http_session.timeout = 10
    except Exception as init_err:
        logger.error(f"NetBox Init Error: {init_err}")


def ensure_custom_fields(nb):
    """Ensure required custom fields exist in NetBox for Virtual Machines."""
    if not nb:
        return
    try:
        fields_to_create = [
            {
                "name": "docker_port",
                "label": "Docker Port",
                "type": "text",
                "weight": 100,
                "description": "External port(s) mapped on the host",
                "filter_logic": "loose",
                "ui_visibility": "read-write",
                "object_types": ["virtualization.virtualmachine"]
            },
            {
                "name": "public_url",
                "label": "Public URL",
                "type": "url",
                "weight": 110,
                "description": "Direct link to the web interface",
                "filter_logic": "loose",
                "ui_visibility": "read-write",
                "object_types": ["virtualization.virtualmachine"]
            },
            {
                "name": "docker_image",
                "label": "Docker Image",
                "type": "text",
                "weight": 120,
                "description": "The container image name",
                "filter_logic": "loose",
                "ui_visibility": "read-write",
                "object_types": ["virtualization.virtualmachine"]
            }
        ]
        for f in fields_to_create:
            try:
                if not nb.extras.custom_fields.get(name=f["name"]):
                    nb.extras.custom_fields.create(f)
                    logger.info(f"  [NetBox] Custom Field '{f['name']}' created.")
            except Exception as cf_err:
                logger.warning(f"  [NetBox] Skipped creating '{f['name']}': {cf_err}")
    except Exception as e:
        logger.warning(f"  [NetBox] Could not setup Custom Fields: {e}")


# noinspection HttpUrlsUsage
def verify_octoprint_html(ip):
    """Check for OctoPrint over both HTTP and HTTPS, handling redirects."""
    endpoints = [
        f"http://{ip}:80",
        f"http://{ip}:5000",
        f"https://{ip}:443",
        f"https://{ip}:5000"
    ]
    for url in endpoints:
        try:
            # noinspection HttpUrlsUsage
            response = requests.get(url, timeout=3, verify=False, allow_redirects=True)

            # Check for either the standard title or the specific redirect URI
            if response.status_code in [200, 302]:
                if "<title>OctoPrint" in response.text or "permissions=STATUS" in response.text:
                    return True
        except requests.RequestException:
            continue
    return False


def parse_docker_ports(raw_ports):
    """Parse raw docker port string to a clean list of external ports."""
    if not raw_ports:
        return ""

    ext_ports = set()
    for part in raw_ports.split(","):
        part = part.strip()
        if "->" in part:
            left_side = part.split("->")[0]
            ext_port = left_side.split(":")[-1]
            if ext_port.isdigit():
                ext_ports.add(int(ext_port))

    if ext_ports:
        sorted_ports = sorted(list(ext_ports))
        return ", ".join(str(p) for p in sorted_ports)
    return ""


def load_local_config():
    inv_path = '/app/inventory.json'
    creds_path = '/app/credentials.json'

    if not os.path.exists(inv_path):
        inv_path = 'inventory.json'
        creds_path = 'credentials.json'

    try:
        with open(inv_path, 'r') as f_inv:
            inv_data = json.load(f_inv)
        with open(creds_path, 'r') as f_creds:
            creds_data = json.load(f_creds)
        return inv_data, creds_data
    except Exception as e:
        logger.error(f"Failed to load local config: {e}")
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
    results = {"vms": [], "containers": [], "host_disks": [],
               "octoprint": verify_octoprint_html(ip), "online": False}

    # Voer de HTTP scan uit ongeacht de SSH status

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        logger.info(f"Connecting to {name} ({ip})...")
        ssh.connect(
            ip,
            username=auth_creds['user'],
            password=auth_creds['pass'],
            timeout=5
        )
        results["online"] = True

        _, stdout, _ = ssh.exec_command("vboxmanage list vms")
        vm_lines = stdout.read().decode().splitlines()
        for line in vm_lines:
            if '"' in line and "<inaccessible>" not in line:
                vm_name = line.split('"')[1]
                vm_data = {
                    "name": vm_name,
                    "memory": None,
                    "vcpus": None,
                    "disk": None,
                    "ip": None
                }

                info_cmd = f'vboxmanage showvminfo "{vm_name}" --machinereadable'
                _, info_out, _ = ssh.exec_command(info_cmd)
                disk_uuid = None

                for iline in info_out.read().decode().splitlines():
                    if iline.startswith("memory="):
                        vm_data["memory"] = int(iline.split("=")[1])
                    elif iline.startswith("cpus="):
                        vm_data["vcpus"] = float(iline.split("=")[1])
                    elif "ImageUUID-0-0" in iline:
                        uuid_val = iline.split("=")[1].strip('"')
                        if uuid_val != "none":
                            disk_uuid = uuid_val

                if disk_uuid:
                    disk_cmd = f'vboxmanage showmediuminfo disk "{disk_uuid}"'
                    _, disk_out, _ = ssh.exec_command(disk_cmd)
                    for dline in disk_out.read().decode().splitlines():
                        if dline.startswith("Capacity:"):
                            try:
                                cap_str = dline.split(":")[1].strip().split()[0]
                                vm_data["disk"] = int(cap_str) // 1024
                            except (ValueError, IndexError):
                                pass
                            break

                ip_cmd = (
                    f'vboxmanage guestproperty get "{vm_name}" '
                    '"/VirtualBox/GuestInfo/Net/0/V4/IP"'
                )
                _, ip_out, _ = ssh.exec_command(ip_cmd)
                ip_resp = ip_out.read().decode().strip()
                if "Value: " in ip_resp:
                    vm_data["ip"] = ip_resp.split("Value: ")[1]

                results["vms"].append(vm_data)

        docker_cmd = (
            "docker ps --format '{\"name\": \"{{.Names}}\", "
            "\"image\": \"{{.Image}}\", \"created\": \"{{.CreatedAt}}\", "
            "\"ports\": \"{{.Ports}}\"}'"
        )
        _, stdout, _ = ssh.exec_command(docker_cmd)

        for line in stdout.read().decode().splitlines():
            try:
                results["containers"].append(json.loads(line))
            except json.JSONDecodeError:
                continue

        _, stdout_df, _ = ssh.exec_command("df -BG | grep '^/dev/'")
        df_out = stdout_df.read().decode().splitlines()
        if df_out:
            for line in df_out:
                parts = line.split()
                if len(parts) >= 6:
                    results["host_disks"].append({
                        "disk": parts[0],
                        "size_gb": parts[1].replace('G', ''),
                        "free_gb": parts[3].replace('G', ''),
                        "mount": parts[5]
                    })
        else:
            cmd = "wmic logicaldisk get Caption,FreeSpace,Size"
            _, stdout_wmic, _ = ssh.exec_command(cmd)
            wmic_out = stdout_wmic.read().decode().splitlines()
            for line in wmic_out:
                parts = line.strip().split()
                if len(parts) >= 3 and parts[0] != "Caption":
                    try:
                        drive = parts[0]
                        free_b = int(parts[1])
                        size_b = int(parts[2])
                        results["host_disks"].append({
                            "disk": drive,
                            "size_gb": size_b // (1024 ** 3),
                            "free_gb": free_b // (1024 ** 3),
                            "mount": drive
                        })
                    except (ValueError, IndexError):
                        continue

        logger.info(f"  [Scan] Found {len(results['host_disks'])} host disks.")
        return results
    except Exception as e:
        logger.warning(f"  [Offline] {name}: {e}")
        if results["octoprint"]:
            logger.info(
                f"  [Scan] SSH failed, but OctoPrint web interface found on {ip}.")
            return results
        return None
    finally:
        ssh.close()


def sync_device_to_netbox(nb, name, host_disks):
    if not host_disks:
        return

    logger.info(f"  [NetBox] Looking up Device '{name}' to sync disks...")
    device = nb.dcim.devices.get(name=name)

    if not device:
        logger.warning(f"  [NetBox] Device EXACT MATCH for '{name}' NOT FOUND.")
        return

    logger.info(f"  [NetBox] Device '{name}' found. Updating comments...")

    md_lines = [
        "### Host Disk Storage",
        "| Drive/Mount | Total Size (GB) | Free Space (GB) |",
        "|---|---|---|"
    ]

    for d in host_disks:
        md_lines.append(f"| `{d['disk']}` | {d['size_gb']} | {d['free_gb']} |")

    if name.lower() == "mail":
        md_lines.append(
            "\n> **WARNING:** Do not change the hostname of this "
            "device! The mail server FQDN and email "
            "delivery heavily depend on it."
        )

    md_lines.append("\n*Auto-discovered by Sovereign Stack Infra-Scanner.*")

    device.comments = "\n".join(md_lines)
    device.save()
    logger.info(f"  [NetBox] Host disks successfully synced to Device '{name}'.")


def sync_vm_to_netbox(
    nb, name, cluster_id, comments, vcpus=None, memory=None,
    disk=None, ip_address=None, docker_ports=None, docker_image=None
):
    vm_params = {
        "name": name,
        "cluster": cluster_id,
        "status": "active",
        "comments": comments
    }
    if vcpus: vm_params["vcpus"] = vcpus
    if memory: vm_params["memory"] = memory
    if disk: vm_params["disk"] = disk

    vm_params["custom_fields"] = {}
    if docker_ports:
        vm_params["custom_fields"]["docker_port"] = docker_ports
    if docker_image:
        vm_params["custom_fields"]["docker_image"] = docker_image

    vm = nb.virtualization.virtual_machines.get(name=name, cluster_id=cluster_id)
    if not vm:
        vm = nb.virtualization.virtual_machines.create(vm_params)
    else:
        for key, value in vm_params.items():
            if key == "custom_fields":
                current_cfs = getattr(vm, "custom_fields", {})
                if isinstance(current_cfs, dict):
                    current_cfs.update(value)
                    setattr(vm, "custom_fields", current_cfs)
            else:
                setattr(vm, key, value)
        vm.save()

    if ip_address and not ip_address.startswith("10.0.2."):
        if "/" not in ip_address:
            ip_address = f"{ip_address}/24"

        try:
            interface = nb.virtualization.interfaces.get(
                virtual_machine_id=vm.id, name="eth0"
            )
            if not interface:
                interface = nb.virtualization.interfaces.create(
                    virtual_machine=vm.id, name="eth0"
                )

            ip_obj = nb.ipam.ip_addresses.get(address=ip_address)
            if not ip_obj:
                ip_obj = nb.ipam.ip_addresses.create(
                    address=ip_address,
                    assigned_object_type="virtualization.vminterface",
                    assigned_object_id=interface.id
                )
            elif ip_obj.assigned_object_id != interface.id:
                vm_primary = getattr(vm, 'primary_ip4', None)
                if vm_primary and getattr(vm_primary, 'id', None) == ip_obj.id:
                    vm.primary_ip4 = None
                    vm.save()

                ip_obj.assigned_object_type = "virtualization.vminterface"
                ip_obj.assigned_object_id = interface.id
                ip_obj.save()

            current_primary = getattr(vm, 'primary_ip4', None)
            if current_primary is None or getattr(current_primary, 'id',
                                                  None) != ip_obj.id:
                vm.primary_ip4 = ip_obj.id
                vm.save()
        except Exception as ip_err:
            logger.warning(f"  [NetBox Warning] IP {ip_address} issue: {ip_err}")


def sync_to_netbox(host_info, scan_results):
    if DRY_RUN or not nb_client:
        return

    name = host_info['name']
    ip = host_info['ip']

    resolved_cluster_name = CLUSTER_MAPPING.get(ip)
    if resolved_cluster_name:
        logger.info(f"  [Mapping] IP {ip} matched with: '{resolved_cluster_name}'")
    else:
        resolved_cluster_name = f"Cluster-{name}"
        logger.warning(
            f"  [Mapping] IP {ip} NOT FOUND. Fallback: '{resolved_cluster_name}'")

    try:
        if scan_results.get("host_disks"):
            sync_device_to_netbox(
                nb=nb_client,
                name=name,
                host_disks=scan_results["host_disks"]
            )

        if scan_results.get("vms"):
            vb_type = nb_client.virtualization.cluster_types.get(name="VirtualBox")
            if not vb_type:
                vb_type = nb_client.virtualization.cluster_types.create(
                    name="VirtualBox", slug="virtualbox"
                )

            vb_cluster = nb_client.virtualization.clusters.get(
                name=resolved_cluster_name
            )
            if not vb_cluster:
                vb_cluster = nb_client.virtualization.clusters.create(
                    name=resolved_cluster_name, type=vb_type.id
                )

            for vm_data in scan_results["vms"]:
                sync_vm_to_netbox(
                    nb=nb_client,
                    name=vm_data["name"],
                    cluster_id=vb_cluster.id,
                    comments="Auto-discovered VirtualBox VM by infra_scanner.py",
                    vcpus=vm_data.get("vcpus"),
                    memory=vm_data.get("memory"),
                    disk=vm_data.get("disk"),
                    ip_address=vm_data.get("ip")
                )

        if scan_results.get("containers"):
            docker_type = nb_client.virtualization.cluster_types.get(name="Docker")
            if not docker_type:
                docker_type = nb_client.virtualization.cluster_types.create(
                    name="Docker", slug="docker"
                )

            docker_cluster = nb_client.virtualization.clusters.get(
                name=resolved_cluster_name
            )
            if not docker_cluster:
                docker_cluster = nb_client.virtualization.clusters.create(
                    name=resolved_cluster_name, type=docker_type.id
                )

            for c_data in scan_results["containers"]:
                c_name = c_data.get("name")
                c_image = c_data.get("image", "N/A")
                c_created = c_data.get("created", "N/A")

                raw_ports = c_data.get("ports", "")
                parsed_ports = parse_docker_ports(raw_ports)

                if raw_ports:
                    p_list = [
                        f"  - `{p.strip()}`" for p in raw_ports.split(",")
                        if p.strip()
                    ]
                    ports_list = "\n".join(p_list)
                    ports_md = f"**Ports:**\n{ports_list}"
                else:
                    ports_md = "**Ports:** *No ports defined*"

                markdown_comments = (
                    f"### Docker Container Details\n"
                    f"- **Image:** `{c_image}`\n"
                    f"- **Created on:** {c_created}\n"
                    f"- {ports_md}\n\n"
                    f"*Auto-discovered by Sovereign Stack Infra-Scanner.*"
                )

                sync_vm_to_netbox(
                    nb=nb_client,
                    name=c_name,
                    cluster_id=docker_cluster.id,
                    comments=markdown_comments,
                    docker_ports=parsed_ports,
                    docker_image=c_image
                )

        logger.info(f"  [NetBox] Sync completed for {name}")
    except Exception as sync_err:
        logger.error(f"  [NetBox Error] Failed to sync {name}: {sync_err}")


def main():
    log_msg = f"Sovereign Stack Infra-Scanner starting (Version: {__version__})"
    logger.info(log_msg)

    # Ensure Custom Fields are prepared in NetBox
    ensure_custom_fields(nb_client)

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
            "\n" + "*" * 60 + "\nDISCOVERY OUTPUT DATA:\n" +
            report_json + "\n" + "*" * 60
        )

    logger.info("Scan cycle completed.")


if __name__ == "__main__":
    main()
