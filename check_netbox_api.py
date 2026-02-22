#!/usr/bin/env python3
"""
# ==============================================================================
# Sovereign Stack - NetBox API Connectivity Test (Robust Version)
#
# This script verifies the connection to the NetBox API.
# It strips accidental quotes from environment variables.
#
# Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License.
# ==============================================================================
"""

import os
import sys
import pynetbox
from dotenv import load_dotenv


def check_connection():
    """Test the NetBox API connectivity and required objects."""
    load_dotenv()

    # Robust loading: strip accidental quotes from .env values
    nb_url = os.getenv("NETBOX_URL", "").strip('"').strip("'")
    nb_token = os.getenv("NETBOX_API_TOKEN", "").strip('"').strip("'")

    if not nb_url or not nb_token:
        print("ERROR: NETBOX_URL or NETBOX_API_TOKEN is missing in .env")
        sys.exit(1)

    print(f"Connecting to NetBox at: {nb_url}...")
    nb = pynetbox.api(nb_url, token=nb_token)

    try:
        status = nb.status()
        print(f"SUCCESS: Connected to NetBox version {status['netbox-version']}.")

        cluster = nb.virtualization.clusters.get(name="Sovereign-Pi-Cluster")
        if cluster:
            print(f"SUCCESS: Cluster 'Sovereign-Pi-Cluster' found (ID: {cluster.id}).")
        else:
            print("WARNING: Cluster 'Sovereign-Pi-Cluster' NOT found.")

    except Exception as e:
        print(f"FATAL: Could not connect to NetBox API. Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    check_connection()
