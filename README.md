# sovereign-stack v2.1: The Digital Gold Reserve

sovereign-stack is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It provides a professional blueprint for an independent, secure, and privacy-first infrastructure.

---

## 1. Project Structure

| File | Purpose |
| :--- | :--- |
| `install.sh` | **Master Setup Wizard:** Installs dependencies, configures .env, and deploys. |
| `backup_stack.sh` | **Master Backup:** Handles DB dump, AES encryption, SFTP push, and Health Reports. |
| `restore_stack.sh` | **Recovery Utility:** Decrypts archives and re-injects data/databases. |
| `monitor_backup.sh`| **Dead Man's Switch:** Nightly verification of backup integrity with High-Priority alerts. |
| `gen_cert.sh` | **Sovereign SSL:** Manually issue certs from the internal Step-CA. |
| `.env.example` | Template for environment variables and secrets. |

---

## 2. Core Vision & Philosophy
* **Sovereignty:** Reducing dependency on centralized infrastructure and foreign clouds.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **IoT Autonomy:** Local-only CCTV (Frigate) and IoT control (Home Assistant).

---

## 3. Network Topology (Security in Layers)



The stack employs three distinct network zones to ensure maximum isolation:
1. **pi-services (Frontend Bridge):** Connects the Proxy (`npm`) to all web-facing services via internal Docker DNS.
2. **nextcloud-internal (Isolated Backend):** A strictly internal network for the database and cache, protected from lateral movement.
3. **Host Mode:** Services requiring direct system access (`fail2ban`, `glances`, `homeassistant`).

---

## 4. Installation
The stack is designed for a single-command installation on Raspberry Pi OS:

    chmod +x install.sh
    ./install.sh

Follow the on-screen wizard to configure your domain, passwords, and backup paths. For detailed post-install steps (MQTT/Step-CA), see **[INSTALL.md](./INSTALL.md)**.

---

## 5. Security & Active Defense
* **Access Control:** IP-based Whitelisting via Nginx Proxy Manager (NPM).
* **Fail2Ban:** Automated kernel-level blocking of brute-force attempts on public-facing services.
* **UFW:** 'Default Deny' host firewall policy to ensure only required ports are open.

---

## 6. Maintenance & Backup Strategy



Backups are automated via Cron (`03:00` daily). The pipeline is "chained" to ensure data integrity:
1. **Dump:** MariaDB is exported to a flat file.
2. **Archive:** All project files (minus media) are compressed into a tarball.
3. **Encrypt:** Archives are secured with AES-256 (PBKDF2) using OpenSSL.
4. **Push:** Encrypted files are transferred to a Windows workstation via SFTP.
5. **Report:** A High-Priority email with system health (CPU Temp/Load) and a file list attachment is dispatched.

---

## 7. Monitoring (Dead Man's Switch)
At `04:30`, the `monitor_backup.sh` script verifies that a fresh backup exists. If no file is found within the 90-minute window, a **High-Priority Alert** is triggered. This indicates a potential failure in the pipeline, the SFTP connection, or the hardware itself.

---

## 8. Service Hardening & Tweaks
Specific configuration requirements for stack stability:
* **Home Assistant:** Must include the Docker bridge subnet in `trusted_proxies` to allow the reverse proxy.
* **Vaultwarden:** Public signups should be disabled (`SIGNUPS_ALLOWED="false"`) after the initial setup.
* **AdGuard:** Configured with TLS-based upstreams (Freedom.nl) to prevent DNS spoofing and ensure privacy.

---

## 9. Disaster Recovery (Sovereign Insurance)
Your data is only as good as your ability to restore it. 
1. Fetch your latest encrypted archive from your remote workstation.
2. Use the `restore_stack.sh` utility to decrypt and re-inject data.
3. Refer to the **[RESTORE.md](./RESTORE.md)** for the full recovery procedure.

---

## 10. Troubleshooting
For common issues regarding SSL (HSTS), Docker permission errors, or VPN routing, refer to:
👉 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**
