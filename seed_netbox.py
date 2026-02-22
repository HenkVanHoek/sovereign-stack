#!/usr/bin/env python3
"""
# ==============================================================================
#
# File: seed_netbox.py
# Part of the sovereign-stack project.
# Version: 4.3.2 (Sovereign Awakening)
# Sovereign Stack - Network Seeding Utility
#
# Processes Nmap scan data and creates 'Staged' devices in NetBox.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Copyright (c) 2026 Henk van Hoek.
# ==============================================================================
"""

import os
import pynetbox
from dotenv import load_dotenv
from scan_network import run_nmap_scan, parse_nmap_output


def log_message(message):
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


def main():
    load_dotenv()

    # Clean URL and Token from environment
    nb_url = os.getenv("NETBOX_URL", "").replace('"', '').strip()
    if nb_url.endswith('/'):
        nb_url = nb_url[:-1]

    token = os.getenv("NETBOX_API_TOKEN", "").replace('"', '').strip()

    # Initialize NetBox API
    nb = pynetbox.api(nb_url, token=token)

    # Ensure mandatory objects exist
    try:
        site = nb.dcim.sites.get(name="Home") or nb.dcim.sites.create(name="Home",
                                                                      slug="home")
        role = nb.dcim.device_roles.get(name="Staged") or nb.dcim.device_roles.create(
            name="Staged", slug="staged", color="9e9e9e"
        )
        mfg = nb.dcim.manufacturers.get(name="Generic") or nb.dcim.manufacturers.create(
            name="Generic", slug="generic"
        )
        dtype = nb.dcim.device_types.get(
            model="Auto-Discovered") or nb.dcim.device_types.create(
            manufacturer=mfg.id, model="Auto-Discovered", slug="auto-discovered"
        )
    except Exception as e:
        log_message(f"Prerequisite setup failed: {e}")
        return

    subnets = ["192.168.178.0/24"]
    for subnet in subnets:
        log_message(f"Scanning subnet: {subnet}")
        raw_output = run_nmap_scan(subnet)
        discovered = parse_nmap_output(raw_output)

        for dev in discovered:
            mac = dev['mac'].upper()
            ip = dev['ip']
            short_mac = mac.replace(':', '')[-4:]
            expected_name = f"New-Device-{short_mac}"

            # 1. Zoek het apparaat eerst op naam (meest betrouwbaar voor unique constraint)
            device = nb.dcim.devices.get(name=expected_name, site_id=site.id)

            if device:
                # Check if IP exists in IPAM
                existing_ip = nb.ipam.ip_addresses.get(address=f"{ip}/24")

                if not existing_ip:
                    # Journal Entry for extra IP's (.202, .203 etc.)
                    warning_msg = f"FLAG: Extra IP {ip} detected for this MAC. Current NetBox record shows this name is taken."
                    log_message(f"ATTENTION: {warning_msg} ({expected_name})")

                    nb.extras.journal_entries.create(
                        assigned_object_type="dcim.device",
                        assigned_object_id=device.id,
                        kind="warning",
                        comments=warning_msg
                    )
                continue
            # If MAC is unique, create new device
            log_message(f"Seeding new unique device for MAC: {mac} ({ip})")
            short_mac = mac.replace(':', '')[-4:]

            try:
                new_device = nb.dcim.devices.create(
                    name=f"New-Device-{short_mac}",
                    device_type=dtype.id,
                    role=role.id,
                    site=site.id,
                    status='staged'
                )

                new_int = nb.dcim.interfaces.create(
                    device=new_device.id,
                    name="mgmt0",
                    type="other",
                    mac_address=mac
                )

                nb.ipam.ip_addresses.create(
                    address=f"{ip}/24",
                    assigned_object_type="dcim.interface",
                    assigned_object_id=new_int.id,
                    status='active',
                    description="Initial IP discovered by scan"
                )
            except Exception as e:
                log_message(f"Failed to create device for MAC {mac}: {e}")

    log_message("Seeding process completed.")


if __name__ == "__main__":
    main()
