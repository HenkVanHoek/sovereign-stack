# Installation Guide: sovereign-stack

This guide provides the streamlined workflow for deploying the sovereign-stack on a Raspberry Pi 5.

## 1. Quick Start (Automated)
The fastest way to deploy is using the Master Installation Wizard. This script handles system dependencies, Docker installation, and environment configuration.

    chmod +x install.sh
    ./install.sh

## 2. The Setup Wizard Process
During execution, the `install.sh` script will:
1. **Check Dependencies:** Installs `msmtp`, `iptables`, `openssl`, and `curl`.
2. **Verify Docker:** Installs the latest Docker Engine via the official convenience script.
3. **Configure .env:** Prompts you for mandatory variables (Domains, Passwords, SFTP paths) and validates placeholders.
4. **Harden Security:** Sets `chmod 600` on secrets and makes scripts executable.
5. **Launch:** Triggers `docker compose up -d` upon confirmation.

## 3. Manual Post-Installation Steps
Some components require manual initialization once the containers are running:

### A. Retrieve Step-CA Fingerprint
To establish trust with your private CA, retrieve the fingerprint:

    docker exec step-ca step certificate fingerprint root_ca.crt

*Update `STEPCAT_FINGERPRINT` in your .env with this value.*

### B. Identify NPM Certificate ID
Identify the ID for use by other services (like Prosody):

    ls ${DOCKER_ROOT}/npm/letsencrypt/archive

*Update `NPM_CERT_ID` in your .env.*

### C. Create MQTT Users
Users must be created manually within the container:

    docker exec -it mqtt mosquitto_passwd -c /mosquitto/config/password.txt <username>

## 4. Verification
- **Status:** `docker compose ps`
- **Logs:** `docker compose logs -f`
