#!/usr/bin/env python3
"""
# ==============================================================================
#
# File: scan_network.py
# Part of the sovereign-stack project.
# Version: 4.3.1 (Sovereign Awakening)
# Sovereign Stack - Network Discovery Scanner (v4.3.1)
#
# Performs Nmap ARP scans across the Main Network and secondary segments
# to synchronize discovered hosts with NetBox.
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
# along with this program.  If not, see https://www.gnu.org/licenses/.
#
# Copyright (c) 2026 Henk van Hoek.
# ==============================================================================
"""

import os
import sys
import fcntl
import subprocess
import re
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


def run_nmap_scan(target_subnet):
    """Execute Nmap ARP scan to discover IPs and MACs."""
    log_message(f"Scanning subnet: {target_subnet}")
    # -sn: Ping scan (no port scan)
    # -PR: ARP ping (reliable for local MAC discovery)
    # --send-eth: Bypasses the IP layer to send raw ethernet frames
    cmd = ["nmap", "-sn", "-PR", "--send-eth", target_subnet]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        log_message(f"Warning: Scan failed for {target_subnet}: {result.stderr}")
        return ""

    return result.stdout


def parse_nmap_output(output):
    """Extract IP and MAC address pairs from Nmap text output."""
    devices = []
    current_ip = None

    for line in output.splitlines():
        # Identify the IP address line
        ip_match = re.search(r"Nmap scan report for ([\d.]+)", line)
        if ip_match:
            current_ip = ip_match.group(1)

        # Identify the MAC address line and pair it with the last found IP
        mac_match = re.search(r"MAC Address: ([0-9A-F:]{17})", line)
        if mac_match and current_ip:
            devices.append({'ip': current_ip, 'mac': mac_match.group(1)})
            current_ip = None

    return devices


def main():
    """Main execution logic for network synchronization."""
    load_dotenv()

    # 1. Anti-Stacking Protection
    lock_path = "/tmp/sovereign_network_scan.lock"
    lock_file = open(lock_path, "w")
    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        fatal_error("Another network scan instance is already running.")

    # 2. NetBox API Initialization
    nb_url = os.getenv("NETBOX_URL", "").strip('"').strip("'").split(']')[0].strip('[')
    nb_token = os.getenv("NETBOX_API_TOKEN", "").strip('"').strip("'")

    if not nb_url or not nb_token:
        fatal_error("NETBOX_URL or NETBOX_API_TOKEN not found in environment.")

    nb = pynetbox.api(nb_url, token=nb_token)

    # 3. Define Target Subnets
    # Scans the Main Network and the dedicated Switch segment
    subnets = ["192.168.178.0/24", "192.168.0.0/24"]

    all_discovered = []
    for subnet in subnets:
        raw_output = run_nmap_scan(subnet)
        all_discovered.extend(parse_nmap_output(raw_output))

    log_message(f"Total devices found across all subnets: {len(all_discovered)}")

    # 4. NetBox Synchronization Loop
    for dev in all_discovered:
        mac = dev['mac'].upper()
        ip = dev['ip']

        # Match discovered MAC against NetBox DCIM interfaces
        interface = nb.dcim.interfaces.get(mac_address=mac)

        if interface:
            device_name = interface.device.name
            log_message(f"Matching device found: {device_name} ({ip})")

            try:
                # Synchronize IPAM status
                full_ip = f"{ip}/24"
                nb.ipam.ip_addresses.update_or_create(
                    address=full_ip,
                    assigned_object_type="dcim.interface",
                    assigned_object_id=interface.id,
                    status='active',
                    description=f"Auto-synced by Sovereign Scan on {datetime.now().date()}"
                )
            except Exception as e:
                log_message(f"Failed to sync IP {ip} for {device_name}: {e}")
        else:
            log_message(
                f"Unregistered MAC discovered: {mac} at {ip}. Requires staging.")

    log_message("Network discovery and synchronization complete.")


if __name__ == "__main__":
    main()
