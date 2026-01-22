Ik heb de README.md volledig bijgewerkt op basis van de door jou gestuurde tekst en de bestandsstructuur uit de afbeelding. Sectie 3 bevat nu alle zichtbare bestanden, en sectie 5 en 8 zijn aangepast om de overgang naar INSTALL.sh, de lokale integriteitscontrole en de Wake-on-LAN functionaliteit te reflecteren.

Hier is de volledige, bijgewerkte inhoud in platte tekst:

# sovereign-stack v3.0: The Sovereign Blueprint

The **sovereign-stack** is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It is a robust, privacy-first infrastructure blueprint designed for those who believe that data sovereignty is a fundamental right.

This stack is designed to be a **complete replacement for proprietary ecosystems**. By deploying this blueprint, you can replace centralized communication tools like **WhatsApp** and **Signal** with your own **Prosody (XMPP)** infrastructure, and transition away from **Microsoft Office/365** or **Google Workspace** by utilizing the full power of **Nextcloud**.

Although it is tested and running on a Raspberry Pi 5 with a 1TB NVMe SSD, it can be easily installed on other hardware using Debian Linux with small adaptations, as Raspberry Pi OS is a Debian variant.

---

## 1. Core Vision & Philosophy
In an era of centralized "cloud" monopolies and constant data harvesting, this project provides a path to technical independence.

* **Autonomy:** Reducing dependency on centralized infrastructure and foreign "Big Tech" clouds.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **Agency:** Utilizing hardware (like CCTV/NVR) without allowing it to "phone home" to foreign servers.
* **Resilience:** Services remain functional and trusted even if external certificate authorities or providers fail.

---

## 2. The Sovereign Service Suite (19+ Services)
The stack is a curated collection of industry-standard services, optimized to run harmoniously on the Raspberry Pi 5.

### Core Infrastructure & Cloud
| Service                                                   | Role            | Purpose                                                                                |
|:----------------------------------------------------------|:----------------|:---------------------------------------------------------------------------------------|
| **[Nextcloud](https://nextcloud.com/)**                   | Cloud Hub       | **Office/365 Replacement:** File sync, contacts, calendar, and collaborative office.   |
| **[Forgejo](https://forgejo.org/)**                       | Git Service     | **GitHub Replacement:** Self-hosted software forge for local code and version control. |
| **[MariaDB](https://mariadb.org/)**                       | SQL Database    | High-performance backend for Nextcloud and other services.                             |
| **[Redis](https://redis.io/)**                            | In-memory Cache | Acceleration for Nextcloud file locking and session handling.                          |
| **[Nginx Proxy Manager](https://nginxproxymanager.com/)** | Reverse Proxy   | Manages SSL (Let's Encrypt/Step-CA) and secure traffic routing.                        |

### Communication & Privacy
| Service                                                               | Role             | Purpose                                                                                 |
|:----------------------------------------------------------------------|:-----------------|:----------------------------------------------------------------------------------------|
| **[Prosody](https://prosody.im/)**                                    | XMPP Server      | **WhatsApp/Signal Replacement:** Private, lightweight, and federated instant messaging. |
| **[AdGuard Home](https://adguard.com/en/adguard-home/overview.html)** | DNS & Ad-block   | Network-wide ad-blocking and privacy-focused DNS (DoH/DoT).                             |
| **[Step-CA](https://smallstep.com/certificates/)**                    | Internal PKI     | Your own Certificate Authority for internal TLS/SSL management.                         |
| **[Vaultwarden](https://github.com/dani-garcia/vaultwarden)**         | Password Manager | Bitwarden-compatible server for secure credential storage.                              |
| **[Fail2Ban](https://www.fail2ban.org/)**                             | Active Defense   | Automated intrusion prevention; blocks malicious IP addresses.                          |

### Home Automation & Intelligence
| Service                                              | Role              | Purpose                                                            |
|:-----------------------------------------------------|:------------------|:-------------------------------------------------------------------|
| **[Home Assistant](https://www.home-assistant.io/)** | Automation Engine | The brain of the local smart home (Core/Container version).        |
| **[Frigate NVR](https://frigate.video/)**            | AI Surveillance   | Real-time object detection and local video recording (NVR).        |
| **[Mosquitto](https://mosquitto.org/)**              | MQTT Broker       | Lightweight communication protocol for IoT sensors and devices.    |
| **[Zigbee2MQTT](https://www.zigbee2mqtt.io/)**       | Device Bridge     | Integrates Zigbee devices into the stack without proprietary hubs. |

### Management & Monitoring
| Service                                              | Role              | Purpose                                                              |
|:-----------------------------------------------------|:------------------|:---------------------------------------------------------------------|
| **[Homarr](https://homarr.dev/)**                    | Service Dashboard | A unified 'Single Pane of Glass' to access and monitor all services. |
| **[Portainer](https://www.portainer.io/)**           | Container GUI     | Visual management of all Docker containers and images.               |
| **[Glances](https://nicolargo.github.io/glances/)**  | System Monitor    | Real-time dashboard for CPU, RAM, Disk, and Temperature.             |
| **[Watchtower](https://containrrr.dev/watchtower/)** | Auto-Update       | Ensures all containers stay up-to-date with security patches.        |
| **[msmtp](https://marlam.de/msmtp/)**                | Alert Pipeline    | SMTP client to dispatch high-priority health alerts (Freedom.nl).    |

---

## 3. Project Structure

| File / Directory            | Purpose                                                                             |
|:----------------------------|:------------------------------------------------------------------------------------|
| `.editorconfig`             | Enforces consistent coding styles across editors.                                   |
| `.env`                      | **Active Secrets:** Local environment variables (Git-ignored).                      |
| `.env.example`              | Template for environment variables and secrets.                                     |
| `.gitignore`                | Defines which files and folders Git should ignore.                                  |
| `backup_stack.sh`           | **Master Backup:** Handles DB dump, AES encryption, and SFTP push.                  |
| `docker-compose.yaml`       | **Master Orchestration:** Defines all 19+ services and networks.                    |
| `Checklist.md`              | **Pre-Flight:** Final verification steps before live deployment. [cite: 2026-01-22] |
| `First-Run Guide.md`        | Quick-start documentation for initial service configuration.                        |
| `fix-nextcloud-perms.sh`    | Utility script to reset Nextcloud data directory permissions.                       |
| `gen_cert.sh`               | **Sovereign SSL:** Manually issue certs from the internal Step-CA.                  |
| `INSTALL.md`                | Comprehensive step-by-step deployment and tuning guide.                             |
| `INSTALL.sh`                | **Master Setup Wizard:** Installs dependencies and configures .env.                 |
| `LICENSE`                   | Project license (GPL-3.0).                                                          |
| `monitor_backup.sh`         | **Dead Man's Switch:** Integrity check and cross-platform verification.             |
| `README.md`                 | **The Blueprint:** This main project overview file.                                 |
| `RESTORE.md`                | **Recovery Manual:** Detailed steps for disaster recovery.                          |
| `restore_stack.sh`          | **Recovery Utility:** Decrypts archives and re-injects databases.                   |
| `test_remote_connection.sh` | **Connectivity Tester:** Verifies WoL and SSH handshake for backups.                |
| `TROUBLESHOOTING.md`        | Guide for resolving common stack and network issues.                                |

---

## 4. Network Topology (Security in Layers)

The stack employs three distinct network zones to ensure maximum isolation:
1.  **pi-services (Frontend Bridge):** Connects the Proxy (`npm`) to all web-facing services via internal Docker DNS.
2.  **nextcloud-internal (Isolated Backend):** A strictly internal network for the database and cache, protected from lateral movement.
3.  **Host Mode:** Services requiring direct system access (`fail2ban`, `glances`, `homeassistant`).

---

## 5. Installation & Deployment
The stack is designed for a single-command installation on Raspberry Pi OS:

    chmod +x INSTALL.sh
    ./INSTALL.sh

The wizard will guide you through setting up your domain, secrets, and **Backup Granularity**. For detailed post-install steps (MQTT/Step-CA Fingerprints), see **[INSTALL.md](./INSTALL.md)**.

### Permission Management
To ensure proper service operation and backup accessibility, configuration folders should be owned by the local user:

    sudo chown -R $USER:$USER ~/docker/homeassistant
    sudo find ~/docker/homeassistant -type d -exec chmod 755 {} +
    sudo find ~/docker/homeassistant -type f -exec chmod 644 {} +

---

## 6. Security & Active Defense
* **Access Control:** IP-based Whitelisting (ACL) via Nginx Proxy Manager (NPM).
* **Fail2Ban:** Automated kernel-level blocking of brute-force attempts on public-facing services.
* **UFW:** 'Default Deny' host firewall policy to ensure only authorized traffic reaches the host.

---

## 7. Maintenance & Selective Backup Pipeline

Backups are automated via Cron (`03:00` daily). The pipeline is robust and handles Windows-specific path requirements:

1.  **Database Dump:** MariaDB is exported to a flat `.sql` file for clean restoration.
2.  **Granular Exclusions:** Toggle specific data via `.env` (`INCLUDE_FRIGATE_DATA` / `INCLUDE_NEXTCLOUD_DATA`).
3.  **Archive & Encrypt:** Secured with **AES-256-CBC** using **PBKDF2** and OpenSSL.
4.  **SFTP Push:** Archives are transferred to a secure workstation. For Windows targets, use the `/DRIVE:/path` notation in `.env`.
5.  **Robust Loading:** Scripts use a specialized environment loader to strip Windows carriage returns (`\r`), ensuring stability across editing environments.

---

## 8. Monitoring (Dead Man's Switch)
At `04:30`, the `monitor_backup.sh` script performs a multi-layer **Remote Verification**. It is cross-platform compatible and handles the "Path Correction" logic between SFTP and PowerShell:

* **Integrity Check:** Performs a non-destructive local test by decrypting the latest archive in memory to verify the archive stream and password.
* **Wake-on-LAN:** Automatically sends a Magic Packet to the target workstation if it is offline.
* **Windows Integration:** Automatically converts `/H:/` style paths to `H:/` for PowerShell validation on remote targets.
* **Freshness Check:** Verifies that a backup file exists on the target and was created within the last 120 minutes.
* **Alerting:** If verification fails or SSH is unreachable, a **High-Priority Alert** (X-Priority: 1) is dispatched via msmtp.

---

## 9. Service Hardening & Tweaks
* **Home Assistant:** Requires `trusted_proxies` config to work behind the reverse proxy.
* **Vaultwarden:** Public signups should be disabled (`SIGNUPS_ALLOWED="false"`) after initial setup.
* **AdGuard:** Configured with TLS-based upstreams (Freedom.nl) to prevent DNS spoofing.

---

## 10. Disaster Recovery (Sovereign Insurance)
The recovery process follows a **Selective Injection** method:
1. **Decrypt:** Use manual OpenSSL to decrypt the archive.
2. **Inject SQL:** Re-import the SQL dump into the active MariaDB container.
3. **Data Sync:** Restore user data and fix permissions (`chown 33:33`).
4. Refer to **[RESTORE.md](./RESTORE.md)** for the full procedure.

---

## 11. Troubleshooting
For common issues regarding SSL (HSTS), Docker permissions, or Windows regeleinden (`\r`) in configuration files:
👉 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

---

## 12. Sovereign Communication (Prosody Clients)

To leverage the privacy guarantees of the Prosody XMPP server, we recommend the following clients that support end-to-end encryption (**OMEMO**):

### Mobile Devices (Android & iOS)
* **Android:** **[Conversations](https://conversations.im/)** is the gold standard.
* **iOS:** **[Monal](https://monal-im.org/)** or **[Siskin IM](https://siskin.im/)**.

### Desktop Devices (Linux, Mac & Windows)
* **Linux:** **[Gajim](https://gajim.org/)** or **[Dino](https://dino.im/)**.
* **macOS:** **[Beagle IM](https://beagle.im/)** or **Monal**.
* **Windows:** **[Gajim](https://gajim.org/)** provides excellent OMEMO support.

---

## 13. License
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

Copyright (c) 2026 Henk van Hoek. Licensed under the **GPL-3.0 License**.
Zal ik ook de First-Run Guide.md voor je bijwerken op basis van deze nieuwe structuur en diensten?
