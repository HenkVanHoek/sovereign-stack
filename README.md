# sovereign-stack v4.0: The Sovereign Blueprint

The **sovereign-stack** is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It is a robust, privacy-first infrastructure blueprint designed for those who believe that data sovereignty is a fundamental right.

This stack is designed to be a **complete replacement for proprietary ecosystems**. By deploying this blueprint, you can replace centralized communication tools like **WhatsApp** and **Signal** with your own **Matrix (Synapse)** infrastructure (hosted externally), and transition away from **Microsoft Office/365** or **Google Workspace**. You can by utilizing the full power of **Nextcloud** with **Collabora Online**.

Although it is tested and running on a Raspberry Pi 5 with a 1TB NVMe SSD, it can be easily installed on other hardware using Debian Linux with small adaptations, as Raspberry Pi OS is a Debian variant.

---

## 1. Core Vision & Philosophy
In an era of centralized "cloud" monopolies and constant data harvesting, this project provides a path to technical independence.

* **Autonomy:** Reducing dependency on centralized infrastructure and foreign "Big Tech" clouds.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **Agency:** Utilizing hardware (like CCTV/NVR) without allowing it to "phone home" to foreign servers.
* **Resilience:** Services remain functional and trusted even if external certificate authorities or providers fail.

---

## 2. The Sovereign Service Suite (Current Stack)
The stack is a curated collection of industry-standard services, optimized to run harmoniously on the Raspberry Pi 5.

### Core Infrastructure & Cloud Office
| Service                                                   | Role            | Purpose                                                                                |
|:----------------------------------------------------------|:----------------|:---------------------------------------------------------------------------------------|
| **[Nextcloud](https://nextcloud.com/)**                   | Cloud Hub       | **Office/365 Replacement:** File sync, contacts, calendar, and collaborative office.   |
| **[Forgejo](https://forgejo.org/)**                       | Git Service     | **GitHub Replacement:** Self-hosted software forge for local code and version control. |
| **[MariaDB](https://mariadb.org/)**                       | SQL Database    | High-performance backend for Nextcloud and Forgejo.                                    |
| **[Redis](https://redis.io/)**                            | In-memory Cache | Acceleration for Nextcloud file locking and session handling.                          |
| **[Nginx Proxy Manager](https://nginxproxymanager.com/)** | Reverse Proxy   | Manages SSL, CORS headers, and secure traffic routing for all internal/external nodes. |

### Communication & Privacy
| Service                                                               | Role             | Purpose                                                         |
|:----------------------------------------------------------------------|:-----------------|:----------------------------------------------------------------|
| **[Signal-API](https://github.com/bbernhard/signal-cli-rest-api)**    | Messaging Bridge | REST API wrapper for Signal-cli, used for automated messaging.  |
| **[AdGuard Home](https://adguard.com/en/adguard-home/overview.html)** | DNS & Ad-block   | Network-wide ad-blocking and privacy-focused DNS (DoH/DoT).     |
| **[Step-CA](https://smallstep.com/certificates/)**                    | Internal PKI     | Your own Certificate Authority for internal TLS/SSL management. |
| **[Vaultwarden](https://github.com/dani-garcia/vaultwarden)**         | Password Manager | Bitwarden-compatible server for secure credential storage.      |
| **[Fail2Ban](https://www.fail2ban.org/)**                             | Active Defense   | Automated intrusion prevention; blocks malicious IP addresses.  |

### Home Automation & Physical Security
| Service                                              | Role            | Purpose                                                                                          |
|:-----------------------------------------------------|:----------------|:-------------------------------------------------------------------------------------------------|
| **[Home Assistant](https://www.home-assistant.io/)** | Automation Core | Local control of IoT devices, lights, and energy management without cloud dependency.            |
| **[Frigate](https://frigate.video/)**                | NVR / AI        | Real-time local object detection (CCTV) utilizing the Coral TPU or CPU for person/car detection. |
| **[Mosquitto](https://mosquitto.org/)**              | MQTT Broker     | Lightweight message bus for communication between Home Assistant, Frigate, and IoT devices.      |

### System & Maintenance
| Service                                              | Role           | Purpose                                                                      |
|:-----------------------------------------------------|:---------------|:-----------------------------------------------------------------------------|
| **[Homarr](https://homarr.dev/)**                    | Dashboard      | Sleek, customizable homepage to monitor and access all sovereign services.   |
| **[Portainer](https://www.portainer.io/)**           | Container Mgmt | GUI for managing Docker containers, images, and networks.                    |
| **[Netbox](https://netboxlabs.com/)**                | IPAM & DCIM    | Infrastructure resource modeling, IP address management, and device racking. |
| **[Glances](https://nicolargo.github.io/glances/)**  | Telemetry      | Cross-platform system monitoring tool (integrated with Home Assistant).      |
| **[Watchtower](https://containrrr.dev/watchtower/)** | Updates        | Automates the process of keeping Docker base images up-to-date.              |
| **[MSMTP](https://marlam.de/msmtp/)**                | Mail Relay     | Lightweight SMTP client for sending system alerts and backup notifications.  |

---

## 2.1 Externalized & Federated Services (Work in Progress)
To maintain peak performance on the ARM-based Raspberry Pi 5, highly resource-intensive services can be externalized to a secondary node (e.g., an Intel i3 server). The Pi's Nginx Proxy Manager securely routes traffic to these external nodes.

* **Matrix (Synapse):** A federated communication server designed to replace WhatsApp/Signal.
    * *Architecture Note:* While Synapse runs flawlessly on ARM processors, hosting multiple heavy instances for large communities (1000+ users) alongside Nextcloud and Frigate exceeds the optimal resource limits of a single Raspberry Pi. For heavy workloads, Synapse is externalized.
    * *Federation Domain Example:* `matrix.piselfhosting.com`
    * *Alternative:* For small, private groups, a lightweight Matrix alternative (**Conduit**) is included in the `docker-compose.yaml` as an optional, commented-out service.

## 3. Project Structure

| File / Directory                        | Purpose                                                                             |
|:----------------------------------------|:------------------------------------------------------------------------------------|
| `.editorconfig`                         | Ensures consistent coding styles across different editors and IDEs (PyCharm).       |
| `.env`                                  | **NOT INCLUDED.** Copy from `.env.example` and populate with your local secrets.    |
| `.env.example`                          | Template for environment variables and secrets (Anonymized).                        |
| `.gitignore`                            | Defines which files and directories should be ignored by Git (e.g., .env).          |
| `adr/`                                  | **Architecture Decision Records:** Documentation of key technical decisions.        |
| `backup_stack.sh`                       | **Master Backup:** Handles DB dump, AES encryption, and SFTP push.                  |
| `CHANGELOG.md`                          | Chronological log of all notable changes and version updates.                       |
| `check_env_consistency.sh`              | **Audit Tool:** Ensures parity between .env, .env.example, and validation logic.    |
| `Checklist.md`                          | **Pre-Flight:** Final verification steps before live deployment.                    |
| `clean_stack.sh`                        | Maintenance script to prune unused Docker images, containers, and networks.         |
| `create_users.sh`                       | Helper script to initialize system users and group permissions.                     |
| `docker-compose.yaml`                   | **Master Orchestration:** Defines all 19+ services and networks.                    |
| `First-Run Guide.md`                    | Step-by-step instructions for initial setup after installation.                     |
| `fix-nextcloud-perms.sh`                | Surgical permission fix for Nextcloud data and preview directories.                 |
| `gen_cert.sh`                           | Utility to generate or renew internal SSL certificates using Step-CA.               |
| `INSTALL.md`                            | Comprehensive technical guide for manual or specialized installations.              |
| `INSTALL.sh`                            | **Master Setup Wizard:** Installs dependencies and configures the environment.      |
| `LICENSE`                               | Project license (GNU GPL-3.0).                                                      |
| `MAINTENANCE.md`                        | Operational guide for updates, scaling, and routine service management.             |
| `monitor_backup.sh`                     | **Dead Man's Switch:** Integrity check and cross-platform verification.             |
| `RESTORE.md`                            | Detailed manual restoration procedure for disaster recovery scenarios.              |
| `restore_files_from_a_given_backup.cmd` | Windows helper script to extract specific files from backups.                       |
| `restore_stack.sh`                      | **Recovery Engine:** Automates the decryption and injection of stack backups.       |
| `TECHNICAL_SPEC.md`                     | **Source of Truth:** Defines all technical requirements and script flows.           |
| `test_remote_connection.sh`             | Debug utility to verify SSH and SFTP connectivity to backup targets.                |
| `TROUBLESHOOTING.md`                    | Central database of common issues, error codes, and their resolutions.              |
| `verify_env.sh`                         | **The Gatekeeper:** Validates all mandatory environment variables before execution. |
| `wake_target.sh`                        | **WOL Utility:** Modular script to wake remote targets via Magic Packets.           |

---

## 4. Operational Standards & Permissions
To maintain stability across updates and container restarts, strict adherence to these standards is required:

1.  **YAML Formatting:**
    * All `docker-compose.yaml` files must use **2 spaces** for indentation.
    * All passwords must be enclosed in double quotes (`"password"`).

2.  **Surgical Permissions (Post-Maintenance):**
    * Avoid using broad `chown -R` commands on the project root.
    * If file permissions are reset during maintenance, restore service-specific ownership immediately:
        * **Nextcloud:** `sudo chown -R 33:33 ./nextcloud/data`
        * **MariaDB:** `sudo chown -R 999:999 ./nextcloud/db`

---

## 5. Safety Guards (Sovereign Security)
Every script in this stack is protected by a multi-layer security shell:
1.  **Root Prevention:** Blocks execution as root/sudo to protect SSH identities.
2.  **Anti-Stacking (Flock):** Kernel-level locking prevents concurrent process pile-ups.
3.  **Environment Guard:** `verify_env.sh` ensures all required secrets are present.
4.  **Path Validation:** Explicit checks for `DOCKER_ROOT` existence before any I/O operation.

---

## 6. Maintenance & Backup Pipeline
Backups are automated and secured with industry-standard encryption:

* **Database:** MariaDB is exported via `mariadb-dump` to a secure SQL file.
* **Granular Excludes:** Dynamically excludes Frigate videos or Nextcloud data via `.env`.
* **Security:** Archives are secured with **AES-256-CBC** (PBKDF2) using OpenSSL.
* **Dynamic Retention:** Automatically purges local backups older than `${BACKUP_RETENTION_DAYS}`.
* **SFTP Push:** Transfers archives to remote targets. Supports Windows paths (`/H:/Backup`).

---

## 7. Monitoring (Dead Man's Switch)
The `monitor_backup.sh` script performs a multi-layer health check every morning:

* **Integrity Test:** Decrypts the latest archive in-memory to verify stream and password.
* **Cross-Platform Check:** Employs OS-aware logic to verify file presence on the target.
* **Windows Logic:** Automatically strips leading slashes for Windows CMD (`if exist`) compatibility.
* **WOL Integration:** Uses `wake_target.sh` to ensure the remote target is awake before checking.
* **Email Alerting:** Dispatches high-priority (X-Priority: 1) status reports via `msmtp`.

---

## 8. Disaster Recovery
The recovery process follows the **Selective Injection** method:
1. **Decrypt:** Use OpenSSL to decrypt the archive.
2. **Inject SQL:** Re-import the SQL dump into the MariaDB container.
3. **Data Sync:** Restore user data and fix permissions (`chown 33:33`).
4. Refer to **[RESTORE.md](./RESTORE.md)** for the full procedure.

---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
