
# Installation Guide: sovereign-stack

    This guide ensures your Raspberry Pi 5 is correctly configured 
    before deploying the sovereign-stack services.

    ## 1. Automated Setup
    Run the provided installation helper to check for dependencies 
    and install the latest Docker engine:

    ```bash
    chmod +x INSTALL.sh
    ./INSTALL.sh
    ```

    ## 2. Required Software Packages
    The stack relies on several host-level utilities for security 
    and maintenance:

    - **msmtp**: Handles SMTP relay for Fail2Ban and Backup alerts.
    - **iptables**: Critical for Fail2Ban to block malicious IPs.
    - **openssl**: Used for AES-256 encryption of your data backups.
    - **curl**: Used for health monitoring and internal API calls.
    - **ca-certificates**: Essential for establishing trust with 
      external and internal Step-CA endpoints.
    - **Docker Compose (V2)**: The orchestration engine for all services.

    ## 3. Post-Installation Hardening
    After the script finishes, ensure your environment variables 
    are secured to prevent unauthorized access to your passwords:

    ```bash
    chmod 600 .env
    ```

    ## 4. Verification
    Confirm that Docker is running correctly:
    `docker compose version`
    `docker ps`
