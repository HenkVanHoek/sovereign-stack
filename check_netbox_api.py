# ==============================================================================
# Sovereign Stack - NetBox API Debugger
#
# Purpose:
#   Validates connectivity, authorization, and data payload structure
#   between the infra-scanner and the NetBox instance.
# ==============================================================================

import os
import logging
import pynetbox
import requests
from dotenv import load_dotenv

# Configure detailed logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("NetBoxDebug")

load_dotenv()
NETBOX_URL = os.getenv("NETBOX_URL")
NETBOX_TOKEN = os.getenv("NETBOX_API_TOKEN")


def test_connection():
    logger.info(f"Initiating connection test to: {NETBOX_URL}")

    if not NETBOX_URL or not NETBOX_TOKEN:
        logger.error("Missing NETBOX_URL or NETBOX_TOKEN in .env file.")
        return

    try:
        # Initialize client
        nb = pynetbox.api(NETBOX_URL, token=NETBOX_TOKEN)

        # Debug: Show masked token for verification
        masked_token = f"{NETBOX_TOKEN[:4]}...{NETBOX_TOKEN[-4:]}"
        logger.debug(f"Using Token: {masked_token}")

        # 1. Test Status (Basic connectivity)
        logger.debug("Attempting to fetch NetBox status...")
        status = nb.status()
        logger.info(
            f"Successfully connected! NetBox version: {status.get('netbox-version')}")

        # 2. Test Authorization (Write permissions check)
        logger.debug("Checking authorization for Virtualization objects...")
        try:
            # We only 'list' to check read-access first
            clusters = nb.virtualization.clusters.all(limit=1)
            logger.info("Read access to Virtualization: OK")
        except pynetbox.RequestError as e:
            logger.error(f"Authorization failed or insufficient permissions: {e}")
            return

        # 3. Payload Preview (What would be sent)
        test_payload = {
            "name": "Debug-VM-Test",
            "cluster": 1,  # Placeholder ID
            "status": "active"
        }
        logger.debug(f"Example VM Payload: {test_payload}")

    except requests.exceptions.ConnectionError as ce:
        logger.error(f"Network Unreachable: {ce}")
    except Exception as ge:
        logger.error(f"An unexpected error occurred: {ge}")


if __name__ == "__main__":
    test_connection()
