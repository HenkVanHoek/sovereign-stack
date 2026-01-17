# SovereignStack v2.1: The Digital Gold Reserve

SovereignStack is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It provides a professional blueprint for an independent, secure, and privacy-first infrastructure, serving as the reference model for the **PiSelfhosting** project.

---

## 1. Project Structure

| File | Purpose |
| :--- | :--- |
| `.env.example` | Template for environment variables and secrets. |
| `README.md` | Main project documentation and architecture overview. |
| `TROUBLESHOOTING.md` | Detailed guide for resolving common SSL, network, and browser issues. |
| `backup_stack.sh` | Main script for database dumps and AES-256 encrypted archiving. |
| `docker-compose.yaml` | Docker orchestration file defining all services and networks. |
| `gen_cert.sh` | Utility to manually issue certificates from the internal Step-CA. |
| `monitor_backup.sh` | "Dead Man's Switch" script to verify backup integrity and age. |
| `push_backups_to_pc.sh` | Script to handle the SFTP transfer of backups to a remote workstation. |

---

## 2. Core Vision & Philosophy

* **Sovereignty:** Reducing dependency on centralized infrastructure and foreign "cloud" providers.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **IoT Autonomy:** Utilizing hardware (CCTV/Smart Home) without allowing it to "phone home" to external servers.
* **Resilience:** Services remain functional even if external authorities fail.

---

## 3. Network Topology (Security in Layers)

The stack employs three distinct network zones:

1. **pi-services (Frontend Bridge):** Connects the Proxy (`npm`) to web-facing services.
2. **nextcloud-internal (Isolated Backend):** Strictly internal network for database/cache.
3. **Host Mode:** Services requiring direct system access (`fail2ban`, `glances`, `homeassistant`).

---

## 4. Security & Active Defense

### Access Control (NPM ACL)
Access is governed by IP-based Whitelisting. The `Satisfy Any` directive ensures seamless access for the local subnet (`192.168.178.0/24`) and authorized static administrative WAN IPs (e.g., Freedom Internet).

### Fail2Ban Integration
- **Monitoring:** Scans NPM logs for 401/403 errors.
- **Enforcement:** Drops offending IPs via `iptables`.
- **Alerting:** Real-time reports via SMTP relay.

---

## 5. Maintenance & Backup Strategy

### Nightly Pipeline (03:00 - 04:30)
1. **Backup:** `backup_stack.sh` creates encrypted archives.
2. **Transfer:** `push_backups_to_pc.sh` moves archives to an offsite/remote location.
3. **Monitoring:** `monitor_backup.sh` verifies integrity and alerts if a backup is missing.

---

## 6. Deployment & Troubleshooting
For detailed installation steps and common fixes (SSL, permissions, or gateway errors), please refer to:
👉 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

---

## 7. Project PiSelfhosting Roadmap
- [ ] Implement Ansible playbooks for "One-Click" deployment.
- [ ] Automate Step-CA certificate injection for non-proxied services.
- [ ] Create Homarr widgets for live AdGuard and Frigate statistics.
