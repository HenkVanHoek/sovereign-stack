# sovereign-stack v2.2: The Sovereign Blueprint

The **sovereign-stack** is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It is a robust, privacy-first infrastructure blueprint designed for those who believe that data sovereignty is a fundamental right.

---

## 1. Core Vision & Philosophy
In an era of centralized "cloud" monopolies and constant data harvesting, this project provides a path to technical independence.

* **Autonomy:** Reducing dependency on centralized infrastructure and foreign "Big Tech" clouds.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **Agency:** Utilizing hardware (like CCTV/NVR) without allowing it to "phone home" to foreign servers.
* **Resilience:** Services remain functional and trusted even if external certificate authorities or providers fail.

---

## 2. Project Structure

| File | Purpose |
| :--- | :--- |
| `install.sh` | **Master Setup Wizard:** Installs dependencies, configures .env, and deploys. |
| `backup_stack.sh` | **Master Backup:** Handles DB dump, AES encryption, SFTP push, and granular exclusions. |
| `restore_stack.sh` | **Recovery Utility:** Decrypts archives and re-injects data/databases. |
| `monitor_backup.sh`| **Dead Man's Switch:** Nightly verification of remote backup integrity with High-Priority alerts. |
| `gen_cert.sh` | **Sovereign SSL:** Manually issue certs from the internal Step-CA. |
| `.env.example` | Template for environment variables and secrets. |

---

## 3. Network Topology (Security in Layers)

The stack employs three distinct network zones to ensure maximum isolation:
1.  **pi-services (Frontend Bridge):** Connects the Proxy (`npm`) to all web-facing services via internal Docker DNS.
2.  **nextcloud-internal (Isolated Backend):** A strictly internal network for the database and cache, protected from lateral movement.
3.  **Host Mode:** Services requiring direct system access (`fail2ban`, `glances`, `homeassistant`).

---

## 4. Installation & Deployment
The stack is designed for a single-command installation on Raspberry Pi OS:

    chmod +x install.sh
    ./install.sh

The wizard will guide you through setting up your domain, secrets, and **Backup Granularity**. For detailed post-install steps (MQTT/Step-CA Fingerprints), see **[INSTALL.md](./INSTALL.md)**.

---

## 5. Security & Active Defense
* **Access Control:** IP-based Whitelisting (ACL) via Nginx Proxy Manager (NPM).
* **Fail2Ban:** Automated kernel-level blocking of brute-force attempts on public-facing services.
* **UFW:** 'Default Deny' host firewall policy to ensure only authorized traffic reaches the host.

---

## 6. Maintenance & Selective Backup Pipeline



Backups are automated via Cron (`03:00` daily). The pipeline is "chained" to ensure data integrity while respecting storage constraints:

1.  **Database Dump:** MariaDB is exported to a flat `.sql` file for clean restoration.
2.  **Granular Exclusions:** The stack allows you to toggle "Heavy Data" via `.env` variables:
    * `INCLUDE_FRIGATE_DATA`: Toggle (true/false) to include/exclude massive NVR video storage.
    * `INCLUDE_NEXTCLOUD_DATA`: Toggle (true/false) to include/exclude user documents and photos.
3.  **Archive & Encrypt:** Project files are compressed and secured with **AES-256 (PBKDF2)** using OpenSSL.
4.  **SFTP Push:** Encrypted archives are transferred to a secure workstation/PC.
5.  **Clean State:** Raw database folders are excluded in favor of the SQL dump to prevent file-locking corruption.

---

## 7. Monitoring (Dead Man's Switch)
At `04:30`, the `monitor_backup.sh` script performs a **Remote Verification**. It logs into the backup PC via SSH to confirm the file actually arrived. If no fresh file is found within the 90-minute window, a **High-Priority Alert** is dispatched via `msmtp` to indicate a hardware, network, or pipeline failure.

---

## 8. Service Hardening & Tweaks
* **Home Assistant:** Requires `trusted_proxies` config to work behind the reverse proxy.
* **Vaultwarden:** Public signups should be disabled (`SIGNUPS_ALLOWED="false"`) after initial setup.
* **AdGuard:** Configured with TLS-based upstreams (Freedom.nl) to prevent DNS spoofing and ensure privacy.

---

## 9. Disaster Recovery (Sovereign Insurance)
The recovery process follows a **Selective Injection** method:
1. **Decrypt:** Use the `restore_stack.sh` (or manual OpenSSL) to decrypt the archive.
2. **Inject SQL:** Re-import the SQL dump into the active MariaDB container (industry standard for data integrity).
3. **Data Sync:** Restore Nextcloud user data (if included) and fix permissions (`chown 33:33`).
4. Refer to **[RESTORE.md](./RESTORE.md)** for the full procedure.

---

## 10. Troubleshooting
For common issues regarding SSL (HSTS), Docker permissions, or VPN routing:
👉 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

---

## 11. License
This project is licensed under the **GPL-3.0 License**. See the [LICENSE](./LICENSE) file for the full legal text. 
Copyright (c) 2026 Henk van Hoek.
