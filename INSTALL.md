# Installation & Configuration Guide (v4.0)

This guide provides step-by-step instructions to deploy and fine-tune your **sovereign-stack v4.0**.

## 1. Prerequisites
Before starting, ensure you have:
* **Hardware:** Raspberry Pi 5 with an NVMe SSD (1TB recommended).
* **OS:** Raspberry Pi OS (64-bit) or any Debian-based distribution.
* **Network:** Static IP assigned to your Pi; ports 80/443 forwarded if using a public domain.
* **Dependencies:** Docker and Docker Compose (the `INSTALL.sh` script will check for system tools like `openssl`, `msmtp`, and `wakeonlan`).

---

## 2. Initial Deployment

### 2.1 Cloning the Repository
The sovereign-stack is designed to run from a dedicated directory in your home folder. This ensures that security guards function correctly without requiring root privileges.

* **Option A: HTTPS (Recommended for quick setup)**
    Best for users without pre-configured SSH keys on GitHub.

    cd ~
    git clone https://github.com/your-username/sovereign-stack.git
    cd sovereign-stack

* **Option B: SSH (Recommended for developers)**
    Use this if you have added your Pi's public key (`~/.ssh/id_ed25519.pub`) to your GitHub account.

    cd ~
    git clone git@github.com:your-username/sovereign-stack.git
    cd sovereign-stack

### 2.2 Run the Installation Wizard
The wizard will create your local `.env` file and configure your security keys and DNS settings.

    chmod +x INSTALL.sh
    ./INSTALL.sh

### 2.3 Start the Stack
Deploy all 19+ containers in detached mode.

    docker compose up -d

---

## 3. Configuring Remote Access (SSH Keys)

For the automated backup and monitoring pipeline, the Raspberry Pi must be able to log in to your remote workstation (Windows, Linux, or Mac) without a password.

### 3.1 Generate SSH Keys on the Pi
If you haven't already generated a key pair on your Pi:

    ssh-keygen -t ed25519 -C "pi-backup-key"

*Press Enter for all prompts to use the default path and no passphrase.*

### 3.2 Copy the Public Key to your Workstation
Replace `user` and `target-ip` with your workstation's details as defined in your `.env`.

* **For Linux/Mac Workstations:**

    ssh-copy-id user@target-ip

* **For Windows Workstations:**
    Ensure the **OpenSSH Server** is enabled in Windows Settings. Then, manually add the Pi's public key to the `authorized_keys` file:

    cat ~/.ssh/id_ed25519.pub | ssh user@target-ip "powershell -Command 'New-Item -ItemType Directory -Path \$HOME\.ssh -Force; Add-Content -Path \$HOME\.ssh\authorized_keys -Value \$Input'"

### 3.3 Verify Connection
Test the connection from the Pi. You should be logged in without being prompted for a password:

    ssh user@target-ip "echo Connection Successful"

---

## 4. Automated Dependency Management (JIT)

The sovereign-stack is self-maintaining. To ensure the backup pipeline works out-of-the-box, even on fresh OS installs, it utilizes Just-In-Time (JIT) installation.

### 4.1 Automated Tool Installation
The `backup_stack.sh` script automatically detects missing dependencies. For instance, if `wakeonlan` is missing, the script will automatically execute:

    sudo apt-get update && sudo apt-get install -y wakeonlan

### 4.2 Sudo Privileges
The user executing the scripts must have sudo privileges to allow for automated maintenance tasks and binary installations.

---

## 5. Scheduling Automated Backups

To ensure your data is safe, use the system cron table to schedule the backup pipeline.

1.  **Open Crontab:**

    crontab -e

2.  **Add the following lines:**

    # Sovereign Stack Automation v4.0
    # 03:00 - Start Backup Pipeline
    0 3 * * * ~/sovereign-stack/backup_stack.sh

    # 03:30 - Start Integrity Check & Monitoring
    30 3 * * * ~/sovereign-stack/monitor_backup.sh
---

## 6. Matrix: Replacing WhatsApp/Signal

To use Matrix (Conduit) as your primary communication server:

1.  **Verify Domain Delegation:**
    Ensure your `.well-known` settings are correct so external servers can find you.

    curl -v https://matrix.yourdomain.com/.well-known/matrix/server

2.  **Create User:**
    Use a client like **Element X** (Mobile) or **Element Desktop**. Enter your homeserver URL (`https://matrix.yourdomain.com`) and register a new account.
    *Note: Registration is controlled by the `SIGNUPS_ALLOWED` variable in your `.env`.*

---

## 7. Nextcloud & Office: Replacing Microsoft 365

To transition away from Office 365, Nextcloud is paired with Collabora Online.

1.  **Verify Collabora:**
    Open a Word document (`.docx`) in Nextcloud. It should load immediately in the browser via the Collabora container.

2.  **Optimization (Memory Caching):**
    Your stack includes **Redis**. Ensure Nextcloud is utilizing it by checking your `config.php` for the correct Redis host and port (6379).

3.  **Fix Permissions (Surgical):**
    If you encounter "Access Denied" errors, DO NOT run `chown -R` on the root. Use the specific fix:

    sudo chown -R 33:33 ./nextcloud/data

---

## 8. Step-CA: Managing Your Internal Trust

The **Step-CA** service acts as your sovereign Certificate Authority.

1.  **Get your Root Fingerprint:**
    You will need this to connect your clients securely.

    docker exec step-ca step certificate fingerprint /home/step/certs/root_ca.crt

2.  **Generate Internal Certs:**
    Use the provided `gen_cert.sh` script to issue certificates for services that do not face the public internet.

---

## 9. Post-Installation & Dashboard Setup

After deployment, configure the **Homarr** dashboard to display your services.

### 9.1 Verify Container Status
Ensure all services started correctly via the terminal:

    docker compose ps

### 9.2 Initial Homarr Configuration
1.  Navigate to `http://<your-pi-ip>:7575`.
2.  Complete the **Onboarding Wizard** to create your administrator account.
3.  **Enable Docker Integration:**
    Add a new **Docker** integration in the Management settings. Homarr will automatically discover your containers via the mounted Docker socket.

---

## 10. Homarr Service Integration Reference (v4.0)

| Service                 | Icon Name             | Internal Docker URL         | Official Website                                       |
|:------------------------|:----------------------|:----------------------------|:-------------------------------------------------------|
| **Nextcloud**           | `nextcloud`           | `http://nextcloud-app:80`   | [nextcloud.com](https://nextcloud.com)                 |
| **Collabora**           | `libreoffice`         | `http://collabora:9980`     | [collaboraoffice.com](https://collaboraoffice.com)     |
| **Forgejo**             | `forgejo`             | `http://forgejo:3000`       | [forgejo.org](https://forgejo.org)                     |
| **Matrix (Conduit)**    | `matrix`              | `http://matrix:6167`        | [conduit.rs](https://conduit.rs)                       |
| **AdGuard Home**        | `adguard-home`        | `http://adguardhome:3000`   | [adguard.com](https://adguard.com)                     |
| **Vaultwarden**         | `bitwarden`           | `http://vaultwarden:80`     | [bitwarden.com](https://bitwarden.com)                 |
| **Home Assistant**      | `home-assistant`      | `http://homeassistant:8123` | [home-assistant.io](https://home-assistant.io)         |
| **Frigate**             | `frigate`             | `http://frigate:5000`       | [frigate.video](https://frigate.video)                 |
| **Portainer**           | `portainer`           | `http://portainer:9000`     | [portainer.io](https://portainer.io)                   |
| **Nginx Proxy Manager** | `nginx-proxy-manager` | `http://npm:81`             | [nginxproxymanager.com](https://nginxproxymanager.com) |

### 10.1 Adding Widgets
For a sovereign overview, add these widgets to your Homarr board:
* **Docker Widget:** Real-time CPU/RAM usage of every container.
* **System Health:** Summary of your Pi 5 load, SSD space, and temperature.

### 10.2 Saving your Layout
To ensure your dashboard configuration is safe, export your layout via **Management → Boards → Export**. Save this as `homarr_layout.json` in your project root.

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will
