# sovereign-stack v2.3: The Sovereign Blueprint

The **sovereign-stack** is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It is a robust, privacy-first infrastructure blueprint designed for those who believe that data sovereignty is a fundamental right.

---

## 1. Core Vision & Philosophy
In an era of centralized "cloud" monopolies and constant data harvesting, this project provides a path to technical independence.

* **Autonomy:** Reducing dependency on centralized infrastructure and foreign "Big Tech" clouds.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **Agency:** Utilizing hardware (like CCTV/NVR) without allowing it to "phone home" to foreign servers.
* **Resilience:** Services remain functional and trusted even if external certificate authorities or providers fail.

---

## 2. The Sovereign Service Suite (17+ Services)
The stack is a curated collection of industry-standard services, optimized to run harmoniously on the Raspberry Pi 5.

### Core Infrastructure & Cloud
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **Nextcloud** | Cloud Hub | File sync, contacts, calendar, and collaborative office. |
| **MariaDB** | SQL Database | High-performance backend for Nextcloud and other services. |
| **Redis** | In-memory Cache | Acceleration for Nextcloud file locking and session handling. |
| **Nginx Proxy Manager** | Reverse Proxy | Manages SSL (Let's Encrypt/Step-CA) and secure traffic routing. |

### Security & Privacy
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **AdGuard Home** | DNS & Ad-block | Network-wide ad-blocking and privacy-focused DNS (DoH/DoT). |
| **Step-CA** | Internal PKI | Your own Certificate Authority for internal TLS/SSL management. |
| **Vaultwarden** | Password Manager | Bitwarden-compatible server for secure credential storage. |
| **Fail2Ban** | Active Defense | Automated intrusion prevention; blocks malicious IP addresses. |

### Home Automation & Intelligence
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **Home Assistant** | Automation Engine | The brain of the local smart home (Core/Container version). |
| **Frigate NVR** | AI Surveillance | Real-time object detection and local video recording (NVR). |
| **Mosquitto** | MQTT Broker | Lightweight communication protocol for IoT sensors and devices. |
| **Zigbee2MQTT** | Device Bridge | Integrates Zigbee devices into the stack without proprietary hubs. |

### Management & Monitoring
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **Homarr** | Service Dashboard | A unified 'Single Pane of Glass' to access and monitor all services. |
| **Portainer** | Container GUI | Visual management of all Docker containers and images. |
| **Glances** | System Monitor | Real-time dashboard for CPU, RAM, Disk, and Temperature. |
| **Watchtower** | Auto-Update | Ensures all containers stay up-to-date with security patches. |
| **msmtp** | Alert Pipeline | SMTP client to dispatch high-priority health alerts (Freedom.nl). |

---

## 3. Project Structure

| File | Purpose |
| :--- | :--- |
| `install.sh` | **Master Setup Wizard:** Installs dependencies and configures .env. |
| `backup_stack.sh` | **Master Backup:** Handles DB dump, AES encryption, and SFTP push. |
| `monitor_backup.sh`| **Dead Man's Switch:** Nightly cross-platform verification of backups. |
| `restore_stack.sh` | **Recovery Utility:** Decrypts archives and re-injects databases. |
| `gen_cert.sh` | **Sovereign SSL:** Manually issue certs from the internal Step-CA. |
| `.env.example` | Template for environment variables and secrets. |

---

## 4. Network Topology (Security in Layers)

The stack employs three distinct network zones to ensure maximum isolation:
1.  **pi-services (Frontend Bridge):** Connects the Proxy (`npm`) to all web-facing services via internal Docker DNS.
2.  **nextcloud-internal (Isolated Backend):** A strictly internal network for the database and cache, protected from lateral movement.
3.  **Host Mode:** Services requiring direct system access (`fail2ban`, `glances`, `homeassistant`).

---

## 5. Installation & Deployment
The stack is designed for a single-command installation on Raspberry Pi OS:

    chmod +x install.sh
    ./install.sh

The wizard will guide you through setting up your domain, secrets, and **Backup Granularity**. For detailed post-install steps (MQTT/Step-CA Fingerprints), see **[INSTALL.md](./INSTALL.md)**.

---

## 6. Security & Active Defense
* **Access Control:** IP-based Whitelisting (ACL) via Nginx Proxy Manager (NPM).
* **Fail2Ban:** Automated kernel-level blocking of brute-force attempts on public-facing services.
* **UFW:** 'Default Deny' host firewall policy to ensure only authorized traffic reaches the host.

---

## 7. Maintenance & Selective Backup Pipeline



Backups are automated via Cron (`03:00` daily). The pipeline is "chained" to ensure data integrity while respecting storage constraints:

1.  **Database Dump:** MariaDB is exported to a flat `.sql` file for clean restoration.
2.  **Granular Exclusions:** Toggle specific data via `.env` (`INCLUDE_FRIGATE_DATA` / `INCLUDE_NEXTCLOUD_DATA`).
3.  **Archive & Encrypt:** Secured with **AES-256 (PBKDF2)** using OpenSSL.
4.  **SFTP Push:** Archives are transferred to a secure workstation (Windows/Linux/Mac).
5.  **Clean State:** Raw database folders are excluded to prevent binary corruption.

---

## 8. Monitoring (Dead Man's Switch)
At `04:30`, the `monitor_backup.sh` script performs a **Remote Verification**. It is cross-platform compatible (**Windows, Linux, or macOS**) and verifies the file actually arrived on the target machine. If no fresh file is found within 90 minutes, a **High-Priority Alert** is dispatched via msmtp.

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
For common issues regarding SSL (HSTS), Docker permissions, or VPN routing:
👉 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

---

## 12. License
This project is licensed under the **GPL-3.0 License**. 
Copyright (c) 2026 Henk van Hoek.
