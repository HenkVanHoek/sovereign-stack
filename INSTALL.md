# Installation & Configuration Guide (v4.3.0)

This guide provides step-by-step instructions to deploy and fine-tune your **sovereign-stack v4.3.0**.

## 1. Prerequisites
Before starting, ensure you have:
* **Hardware:** Raspberry Pi 5 with an NVMe SSD (1TB recommended).
* **OS:** Raspberry Pi OS (64-bit) or any Debian-based distribution.
* **Network:** Static IP assigned to your Pi.
* **Ports:** Ensure the following ports are forwarded if using a public domain:
    * 80/443 (HTTP/HTTPS)
    * 5222/5269 (XMPP Federation/Client - for future-proofing communication services)
* **Dependencies:** Docker and Docker Compose (the INSTALL.sh script will check for system tools like openssl, msmtp, and wakeonlan).

---

## 2. Initial Deployment

### 2.1 Cloning the Repository
The sovereign-stack is designed to run from a dedicated directory in your home folder. This ensures that security guards function correctly without requiring root privileges.

    cd ~
    git clone [https://github.com/your-username/sovereign-stack.git](https://github.com/your-username/sovereign-stack.git)
    cd sovereign-stack

### 2.2 Run the Installation Wizard
The wizard will create your local .env file and configure your security keys and DNS settings.

    chmod +x INSTALL.sh
    ./INSTALL.sh

---

## 3. Environment Validation (The Sentinel)
Before the stack can be started, you must populate the .env file with your specific credentials. The Sovereign Stack uses a mandatory validation gate to prevent unstable deployments.

1. Edit your environment file:
    vi .env
2. Verify the configuration:
    ./verify_env.sh

Note: The stack will refuse to start if any mandatory variables are missing or incorrectly formatted.

---

## 4. Infrastructure Discovery Setup (NetBox)
Version 4.3.0 introduces automated asset mapping. Before starting the full service suite, you must initialize your inventory management layer.

### 4.1 Prepare Discovery Metadata
Copy the templates and configure your host mappings:

    cp inventory.json.example inventory.json
    cp credentials.json.example credentials.json

* Edit credentials.json with the SSH credentials for your target nodes.
* Edit inventory.json to map your hostnames to the correct NetBox Cluster IDs.

### 4.2 Initial Discovery Scan
Execute the discovery suite to populate NetBox with your existing containers and VMs:

    ./run_task.sh python3 infra_scanner.py
    ./run_task.sh python3 import_inventory.py

---

## 5. Automation & Crontab Configuration
To ensure the reliability and "Sovereign" nature of the stack, maintenance tasks must be automated via the user's crontab.

1. Open the following block (replace REPLACE_WITH_USER with your actual username):

    # Sovereign Stack Automation Schema (v4.3.0)
    # --------------------------------------------------------------------------

    # 1. Daily Infrastructure Backup (03:00)
    0 3 * * * /home/REPLACE_WITH_USER/sovereign-stack/backup_stack.sh > /home/REPLACE_WITH_USER/sovereign-stack/logs/backup.log 2>&1

    # 2. Daily Backup Integrity & Email Report (03:30)
    30 3 * * * /home/REPLACE_WITH_USER/sovereign-stack/monitor_backup.sh > /home/REPLACE_WITH_USER/sovereign-stack/logs/monitor.log 2>&1

    # 3. Daily Infrastructure Discovery (04:00)
    0 4 * * * /home/REPLACE_WITH_USER/sovereign-stack/run_task.sh python3 /home/REPLACE_WITH_USER/sovereign-stack/infra_scanner.py && /home/REPLACE_WITH_USER/sovereign-stack/run_task.sh python3 /home/REPLACE_WITH_USER/sovereign-stack/import_inventory.py >> /home/REPLACE_WITH_USER/sovereign-stack/logs/discovery.log 2>&1

    # 4. Monthly Stack Hygiene (1st of the month at 05:00)
    0 5 1 * * /home/REPLACE_WITH_USER/sovereign-stack/clean_stack.sh >> /home/REPLACE_WITH_USER/sovereign-stack/logs/clean.log 2>&1

---

## 6. Security Hardening
After the initial installation, the stack enforces a strict permission model.

1. Secure the environment file:
    chmod 600 .env
2. Enforce surgical UID ownership:
    ./clean_stack.sh

---

## 7. Service Overview & Access
Once the stack is running (docker compose up -d), services are accessible via the following internal endpoints. It is recommended to configure Homarr as your primary entry point.

| Service                | Container Name        | Internal URL          | Official Source                                   |
| :--------------------- | :-------------------- | :-------------------- | :------------------------------------------------ |
| **Homarr** | homarr                | http://homarr:7575    | [https://homarr.dev](https://homarr.dev)                                |
| **Nextcloud** | nextcloud-app         | http://nextcloud:80   | [https://nextcloud.com](https://nextcloud.com)                             |
| **Forgejo** | forgejo               | http://forgejo:3000   | [https://forgejo.org](https://forgejo.org)                               |
| **NetBox** | netbox                | http://netbox:8085    | [https://netboxlabs.com](https://netboxlabs.com)                             |
| **AdGuard Home** | adguard-home          | http://adguardhome:3000| [https://adguard.com/adguard-home.html](https://adguard.com/adguard-home.html)            |
| **Home Assistant** | home-assistant        | http://homeassistant:8123| [https://home-assistant.io](https://home-assistant.io)                      |
| **Frigate** | frigate               | http://frigate:5000   | [https://frigate.video](https://frigate.video)                             |
| **Nginx Proxy Manager**| nginx-proxy-manager   | http://npm:81         | [https://nginxproxymanager.com](https://nginxproxymanager.com)                     |

---

## 8. Post-Installation
After completing this guide, proceed to the First-Run Guide.md to configure SSL certificates, trust settings for Step-CA, and the Homarr dashboard layout.

---
*This documentation is part of the Sovereign Stack project.
Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0.*
