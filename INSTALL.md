# Installation Guide: sovereign-stack v2.1

    This guide provides the streamlined workflow for deploying the 
    sovereign-stack on a Raspberry Pi 5.

    ## 1. Quick Start (Automated)
    The fastest way to deploy is using the Master Installation Wizard. 
    This script handles system dependencies, Docker installation, 
    and environment configuration.

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

    ## 2. The Setup Wizard Process
    During execution, the `install.sh` script will:
    1. **Check Dependencies:** Installs `msmtp`, `iptables`, `openssl`, etc.
    2. **Verify Docker:** Installs the latest Docker Engine if missing.
    3. **Configure .env:** Prompts you for mandatory variables (Domains, 
       Passwords, SFTP paths) and validates placeholders.
    4. **Harden Security:** Sets `chmod 600` on secrets and prepares scripts.
    5. **Launch:** Optionally triggers `docker compose up -d`.

    ## 3. Manual Post-Installation Steps
    Some sovereign components require manual initialization once the 
    containers are running:

    ### A. Retrieve Step-CA Fingerprint
    To establish trust with your private CA, retrieve the fingerprint:
    `docker exec step-ca step certificate fingerprint root_ca.crt`
    *Copy this value into your `.env` as `STEPCAT_FINGERPRINT`.*

    ### B. Identify NPM Certificate ID
    After creating your first SSL certificate in Nginx Proxy Manager, 
    identify its ID for use by other services (like Prosody):
    `ls ${DOCKER_ROOT}/npm/letsencrypt/archive`
    *Update `NPM_CERT_ID` in your .env accordingly.*

    ### C. Create MQTT Users
    MQTT users for Frigate and Home Assistant must be created manually 
    within the container:
    `docker exec -it mqtt mosquitto_passwd -c /mosquitto/config/password.txt <username>`

    ## 4. Verification & Logs
    Check the status of your deployment:
    - **Service Status:** `docker compose ps`
    - **Real-time Logs:** `docker compose logs -f`
    - **Health Check:** Confirm your dashboard is reachable at 
      `https://home.<your-domain>.com`

    ---
    **Security Note:** Always ensure your `.env` file remains on your 
    local machine and is never committed to GitHub. The `install.sh` 
    script automatically applies `chmod 600` for your protection.
