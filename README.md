# sovereign-stack v3.6: The Sovereign Blueprint

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
| **[Nextcloud](https://nextcloud.com/)** | Cloud Hub       | **Office/365 Replacement:** File sync, contacts, calendar, and collaborative office.   |
| **[Forgejo](https://forgejo.org/)** | Git Service     | **GitHub Replacement:** Self-hosted software forge for local code and version control. |
| **[MariaDB](https://mariadb.org/)** | SQL Database    | High-performance backend for Nextcloud and other services.                             |
| **[Redis](https://redis.io/)** | In-memory Cache | Acceleration for Nextcloud file locking and session handling.                          |
| **[Nginx Proxy Manager](https://nginxproxymanager.com/)** | Reverse Proxy   | Manages SSL (Let's Encrypt/Step-CA) and secure traffic routing.                        |

### Communication & Privacy
| Service                                                               | Role             | Purpose                                                                                 |
|:----------------------------------------------------------------------|:-----------------|:----------------------------------------------------------------------------------------|
| **[Prosody](https://prosody.im/)** | XMPP Server      | **WhatsApp/Signal Replacement:** Private, lightweight, and federated instant messaging. |
| **[AdGuard Home](https://adguard.com/en/adguard-home/overview.html)** | DNS & Ad-block   | Network-wide ad-blocking and privacy-focused DNS (DoH/DoT).                             |
| **[Step-CA](https://smallstep.com/certificates/)** | Internal PKI     | Your own Certificate Authority for internal TLS/SSL management.                         |
| **[Vaultwarden](https://github.com/dani-garcia/vaultwarden)** | Password Manager | Bitwarden-compatible server for secure credential storage.                              |
| **[Fail2Ban](https://www.fail2ban.org/)** | Active Defense   | Automated intrusion prevention; blocks malicious IP addresses.                          |

---

## 3. Project Structure

| File / Directory     | Purpose                                                                             |
|:---------------------|:------------------------------------------------------------------------------------|
| `.env`               | **Active Secrets:** Local environment variables (Git-ignored).                      |
| `.env.example`       | Template for environment variables and secrets.                                     |
| `backup_stack.sh`    | **Master Backup:** Handles DB dump, AES encryption, and SFTP push.                  |
| `Checklist.md`       | **Pre-Flight:** Final verification steps before live deployment.                    |
| `docker-compose.yaml`| **Master Orchestration:** Defines all 19+ services and networks.                    |
| `INSTALL.sh`         | **Master Setup Wizard:** Installs dependencies and configures .env.                 |
| `LICENSE`            | Project license (GNU GPL-3.0).                                                      |
| `monitor_backup.sh`  | **Dead Man's Switch:** Integrity check and cross-platform verification.             |
| `TECHNICAL_SPEC.md`  | **Source of Truth:** Defines all technical requirements and script flows.           |
| `verify_env.sh`      | **The Gatekeeper:** Validates all mandatory environment variables before execution. |
| `wake_target.sh`     | **WOL Utility:** Modular script to wake remote targets via Magic Packets.           |

---

## 4. Safety Guards (Sovereign Security)
Every script in this stack is protected by a multi-layer security shell:
1.  **Root Prevention:** Blocks execution as root/sudo to protect SSH identities.
2.  **Anti-Stacking (Flock):** Kernel-level locking prevents concurrent process pile-ups.
3.  **Environment Guard:** `verify_env.sh` ensures all 11+ required secrets are present.
4.  **Path Validation:** Explicit checks for `DOCKER_ROOT` existence before any I/O operation.

---

## 5. Maintenance & Backup Pipeline
Backups are automated and secured with industry-standard encryption:

* **Database:** MariaDB is exported via `mariadb-dump` to a secure SQL file.
* **Granular Excludes:** Dynamically excludes Frigate videos or Nextcloud data via `.env`.
* **Security:** Archives are secured with **AES-256-CBC** (PBKDF2) using OpenSSL.
* **Dynamic Retention:** Automatically purges local backups older than `${BACKUP_RETENTION_DAYS}`.
* **SFTP Push:** Transfers archives to remote targets. Supports Windows paths (`/H:/Backup`).

---

## 6. Monitoring (Dead Man's Switch)
The `monitor_backup.sh` script performs a multi-layer health check every morning:

* **Integrity Test:** Decrypts the latest archive in-memory to verify stream and password.
* **Cross-Platform Check:** Employs OS-aware logic to verify file presence on the target.
* **Windows Logic:** Automatically strips leading slashes for Windows CMD (`if exist`) compatibility.
* **WOL Integration:** Uses `wake_target.sh` to ensure the remote target is awake before checking.
* **Email Alerting:** Dispatches high-priority (X-Priority: 1) status reports via `msmtp`.

---

## 7. Disaster Recovery
The recovery process follows the **Selective Injection** method:
1. **Decrypt:** Use OpenSSL to decrypt the archive.
2. **Inject SQL:** Re-import the SQL dump into the MariaDB container.
3. **Data Sync:** Restore user data and fix permissions (`chown 33:33`).
4. Refer to **[RESTORE.md](./RESTORE.md)** for the full procedure.

---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
