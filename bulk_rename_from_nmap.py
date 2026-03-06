#!/usr/bin/env python3
"""
# ==============================================================================
# File: bulk_rename_from_nmap.py
# Part of the sovereign-stack project.
# Version: See version.py
#
# Sovereign Stack - Bulk Device Renamer
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
# ==============================================================================
"""

import os
import pynetbox
from dotenv import load_dotenv


def main():
    load_dotenv()
    nb = pynetbox.api(
        os.getenv("NETBOX_URL").strip().rstrip("/"),
        token=os.getenv("NETBOX_API_TOKEN").strip(),
    )

    file_path = "nmap_flat.txt"
    print("--- Starting Unique Device Rename ---")

    # Keep track of used names in this run to avoid duplicates
    used_names = []

    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or ";" not in line:
                continue

            hostname, ip, mac = line.split(";")
            short_mac = (
                mac.replace(":", "").replace("-", "").replace(".", "").upper()[-4:]
            )
            temp_name = f"New-Device-{short_mac}"

            # Clean up the name
            raw_name = hostname.replace(".fritz.box", "").strip()

            # If the name is 'Unknown' or already used, append MAC suffix
            if raw_name == "Unknown" or raw_name in used_names:
                new_name = f"{raw_name}-{short_mac}"
            else:
                new_name = raw_name

            used_names.append(new_name)

            device = nb.dcim.devices.get(name=temp_name)
            if device:
                update_data = {}
                if device.name != new_name:
                    update_data["name"] = new_name

                if not device.primary_ip4:
                    ip_addr = nb.ipam.ip_addresses.get(address=f"{ip}/24")
                    if ip_addr:
                        update_data["primary_ip4"] = ip_addr.id

                if update_data:
                    try:
                        print(f"UPDATING {temp_name} -> {new_name}")
                        device.update(update_data)
                    except Exception as e:
                        print(f"FAILED to update {temp_name}: {e}")
            else:
                # Device might have been renamed in a previous run
                # Check if the new name already exists
                check_exists = nb.dcim.devices.get(name=new_name)
                if check_exists:
                    print(f"ALREADY UPDATED: {new_name}")
                else:
                    print(f"NOT FOUND: {temp_name}")

    print("\n--- Finished ---")


if __name__ == "__main__":
    main()
