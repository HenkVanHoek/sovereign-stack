# Installation & Configuration Guide

This guide provides the step-by-step instructions to deploy and fine-tune your **sovereign-stack**.

## 1. Prerequisites
Before starting, ensure you have:
* **Hardware:** Raspberry Pi 5 with an NVMe SSD (1TB recommended).
* **OS:** Raspberry Pi OS (64-bit) or any Debian-based distribution.
* **Network:** Static IP assigned to your Pi and ports 80/443 forwarded if using a public domain.
* **Dependencies:** Docker and Docker Compose (the `install.sh` script will check for basic system tools like `openssl` and `msmtp`).

---

## 2. Initial Deployment

### 2.1 Cloning the Repository
Depending on your security setup and whether you are working on the Production Pi or your Development Workstation, you can clone the repository using HTTPS or SSH. 

**Assumption:** This project assumes the directory structure is maintained under `/home/hvhoek/docker`.

* **Option A: HTTPS (Recommended for quick setup)**
    This method is the simplest and does not require pre-configured SSH keys on GitHub.

    cd /home/hvhoek
    git clone [https://github.com/HenkVanHoek/sovereign-stack.git](https://github.com/HenkVanHoek/sovereign-stack.git) docker
    cd docker

* **Option B: SSH (Recommended for developers)**
    Use this if you have your Pi's public key (`~/.ssh/id_ed25519.pub`) added to your GitHub account. This is the preferred method for seamless PyCharm integration.

    cd /home/hvhoek
    git clone git@github.com:HenkVanHoek/sovereign-stack.git docker
    cd docker

### 2.2 Run the Installation Wizard
The wizard will create your local `.env` file and configure your security keys. This file is ignored by Git to protect your secrets.
    
    chmod +x install.sh
    ./install.sh

### 2.3 Start the Stack
Deploy all 19+ containers in detached mode.
    
    docker compose up -d

---

## 3. Configuring Remote Access (SSH Keys)

To enable the automated backup and monitoring pipeline, the Raspberry Pi must be able to log in to your remote workstation (Windows, Linux, or Mac) without a password.

### 3.1 Generate SSH Keys on the Pi
If you haven't already generated a key pair on your Pi:

    ssh-keygen -t ed25519 -C "pi-backup-key"

*Press Enter for all prompts to use the default path and no passphrase.*

### 3.2 Copy the Public Key to your Workstation
Replace `user` and `target-ip` with your workstation's details (as defined in your `.env`).

* **For Linux/Mac Workstations:**
    
    ssh-copy-id user@target-ip

* **For Windows Workstations:**
    Ensure the **OpenSSH Server** is enabled in Windows Settings. Then, manually add the Pi's public key to the `authorized_keys` file:

    cat ~/.ssh/id_ed25519.pub | ssh user@target-ip "powershell -Command 'New-Item -ItemType Directory -Path \$HOME\.ssh -Force; Add-Content -Path \$HOME\.ssh\authorized_keys -Value \$Input'"

### 3.3 Verify Connection
Test the connection from the Pi. You should be logged in without being prompted for a password:

    ssh user@target-ip "echo Connection Successful"

---

## 4. Scheduling Automated Backups

To ensure your data is safe, use the system cron table to schedule the backup pipeline. We use `vi` as the default editor.

1.  **Open Crontab:**
    
    crontab -e

2.  **Add the following lines:**
    This schedules the backup at 03:00 and the Dead Man's Switch verification at 04:30.
    
    # Nightly Sovereign Backup (03:00)
    0 3 * * * /home/hvhoek/docker/backup_stack.sh >> /home/hvhoek/docker/backups/cron.log 2>&1

    # Dead Man's Switch Verification (04:30)
    30 4 * * * /home/hvhoek/docker/monitor_backup.sh >> /home/hvhoek/docker/backups/monitor.log 2>&1

---

## 5. Prosody: Replacing WhatsApp/Signal

To use Prosody as your primary communication server, you must create user accounts and ensure the server is discoverable.

1.  **Create your first user:**
    Replace `user` and `yourdomain.com` with your actual details.
    
    docker exec -it prosody prosodyctl register user yourdomain.com yourpassword

2.  **Enable OMEMO (End-to-End Encryption):**
    Ensure your Prosody configuration (`prosody.cfg.lua`) includes `mod_mam` (message archiving) and `mod_pep` to support modern encrypted clients like Conversations or Monal.

3.  **Step-CA Integration:**
    If you are using your internal **Step-CA** for chat encryption, you must import your root certificate onto your mobile device so the chat client trusts the server.

---

## 6. Nextcloud: Replacing Microsoft Office

To transition away from Office 365, Nextcloud needs to be optimized for performance and collaborative editing.

1.  **Enable Office Features:**
    Install the **Nextcloud Office** (Collabora) or **OnlyOffice** app from the Nextcloud App Store via the web interface.

2.  **Optimization (Memory Caching):**
    Your stack includes **Redis**. Ensure Nextcloud is utilizing it by checking the `config.php`:
    
    'memcache.local' => '\OC\Memcache\APCu',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => [
        'host' => 'redis',
        'port' => 6379,
    ],

3.  **Fix Permissions:**
    If you encounter "Access Denied" errors after a restore or migration, run:
    
    sudo chown -R 33:33 nextcloud/data

---

## 7. Step-CA: Managing Your Internal Trust

The **Step-CA** service acts as your sovereign Certificate Authority.

1.  **Get your Root Fingerprint:**
    You will need this to connect your clients securely.
    
    docker exec step-ca step certificate fingerprint /home/step/certs/root_ca.crt

2.  **Generate Internal Certs:**
    Use the provided `gen_cert.sh` script to issue certificates for services that do not face the public internet.

---

## 8. Post-Installation & Dashboard Setup

After deployment, your services are running, but the **Homarr** dashboard needs to be configured to display them.

### 8.1 Verify Container Status
First, ensure all services started correctly via the terminal:

    docker compose ps

### 8.2 Initial Homarr Configuration
1.  Navigate to `http://<your-pi-ip>:7575`.
2.  Complete the **Onboarding Wizard** to create your administrator account.
3.  **Enable Docker Integration:**
    * Go to **Management** -> **Integrations**.
    * Add a new **Docker** integration.
    * Since the Docker socket is mounted in the `docker-compose.yaml`, Homarr will automatically discover your containers.
4.  **Create your Board:**
    * Go to **Management** -> **Boards** and create your primary "Sovereign Dashboard."
    * Use the **"Add from Docker"** feature in edit mode to pull in your running services as tiles.

---

## 9. Homarr Service Integration Reference

When manually adding or editing tiles in Homarr, use the following reference for icons, internal URLs, and official documentation.

### 9.1 Tile Configuration Table

| Service | Icon Name | Internal Docker URL | Official Website |
| :--- | :--- | :--- | :--- |
| **Nextcloud** | `nextcloud` | `http://nextcloud-app:80` | [nextcloud.com](https://nextcloud.com) |
| **Forgejo** | `forgejo` | `http://forgejo:3000` | [forgejo.org](https://forgejo.org) |
| **Prosody** | `prosody` | `http://prosody:5280/admin` | [prosody.im](https://prosody.im) |
| **AdGuard Home** | `adguard-home` | `http://adguardhome:3000` | [adguard.com](https://adguard.com/en/adguard-home/overview.html) |
| **Vaultwarden** | `bitwarden` | `http://vaultwarden:80` | [github.com/dani-garcia/vaultwarden](https://github.com/dani-garcia/vaultwarden) |
| **Home Assistant** | `home-assistant` | `http://homeassistant:8123` | [home-assistant.io](https://www.home-assistant.io) |
| **Frigate** | `frigate` | `http://frigate:5000` | [frigate.video](https://frigate.video) |
| **Nginx Proxy Manager** | `nginx-proxy-manager` | `http://npm:81` | [nginxproxymanager.com](https://nginxproxymanager.com) |
| **Portainer** | `portainer` | `http://portainer:9000" | [portainer.io](https://www.portainer.io) |

### 9.2 Adding Widgets
For a true sovereign overview, add these widgets to your Homarr board:
* **Docker Widget:** Real-time CPU/RAM usage of every container.
* **System Health (Dash.):** Summary of your Pi 5 load, SSD space, and temperature.
* **Nextcloud Calendar:** Connect to your CalDAV URL for a sovereign schedule overview.

### 9.3 Saving your Layout
To ensure your dashboard configuration is safe, export your layout via **Management -> Boards -> Export**. It is recommended to save this as `homarr_layout.json` in your project root.