# sovereign-stack: The Sovereign Blueprint

The **sovereign-stack** is a comprehensive infrastructure project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. This is not just a collection of scripts, but a robust, privacy-first blueprint designed for those who believe that data sovereignty is a fundamental human right in an age of centralized cloud dominance.

### Beyond the Cloud
In an era where "the cloud" is simply someone else's computer, the Sovereign Stack provides a proven path to transition away from proprietary, centralized ecosystems like **Microsoft 365**, **Google Workspace**, or **WhatsApp**. By deploying this blueprint, you move your digital life back within your own physical walls, under your own terms.

### Engineering for Reliability
Building on decades of software engineering experience, this stack emphasizes stability, security, and the "Single Source of Truth" philosophy. Through automated infrastructure discovery and strict operational standards, the Sovereign Stack ensures that your self-hosted environment is as reliable and professional as any commercial enterprise solution.

> **Current Version:** v4.5.0 (See version.py (./version.py) for the Single Source of Truth).

---

## 1. Core Vision & Philosophy
* **Autonomy:** Reducing dependency on centralized "Big Tech" clouds.
* **Privacy:** Keeping personal and community data within your own physical walls.
* **Security:** AES-256 encrypted backups of both local and remote infrastructure.
* **Discovery:** Automated infrastructure mapping via NetBox integration.

---

## 2. Infrastructure Resilience (Backup & Recovery)
The Sovereign Stack features a **3-2-1 backup strategy** designed for disaster recovery and data integrity:

* **3 Copies:** Original data + local backup + off-site backup
* **2 Media Types:** USB 8TB drive (local) + NAS (off-site)
* **1 Off-site:** Synology NAS for disaster recovery

**Backup Locations:**
* Local: `${BACKUP_LOCAL_TARGET}/archives` (USB 8TB drive)
* Off-site: `${BACKUP_OFFSITE_PATH}` (NAS)

**Verification:**
* Local: AES-256-CBC encryption integrity check
* Off-site: SHA256 checksum comparison between local and NAS

**Configuration:** All backup settings are centralized in `.env`:
* `BACKUP_LOCAL_RETENTION_DAYS`: Local backup retention
* `BACKUP_OFFSITE_RETENTION_VERSIONS`: NAS backup retention
* `BACKUP_OFFSITE_WOL`: Wake-on-LAN for NAS

---

## 3. Project Structure
The project follows a "Flat Root" philosophy where all logic and configuration reside within the user's home directory for easier management and version control:

    ~/docker/
    ├── alloy-config/             # Grafana Alloy collector configurations
    ├── data/                     # Persistent volumes for all Docker containers
    ├── etc/                      # Host system integration (e.g. systemd services)
    ├── fail2ban/                 # Intrusion prevention jail and filter rules
    ├── nginx/                    # Reverse proxy custom HTML and well-known configs
    ├── pi-backup/                # Scripts and env templates deployed to backup node
    ├── unifi/                    # UniFi database initialization scripts
    ├── backup_stack.sh           # The primary backup engine (3-2-1 strategy)
    ├── monitor_backup.sh         # Backup verification and health monitoring
    ├── restore_stack.sh          # Restore from encrypted backup
    ├── verify_env.sh             # Environment variable validator
    ├── wake_target.sh            # Wake-on-LAN utility
    ├── backup-rsync.sh           # Legacy rsync backup (alternative)
    ├── test_remote_connection.sh # Remote connection tester
    ├── infra_scanner.py          # Scans infra assets and syncs critical data to NetBox
    ├── import_inventory.py       # Imports container services from docker-compose to NetBox
    ├── scan_network.py           # Runs Nmap sweeps; discovers MAC/IPs for NetBox discovery
    ├── seed_netbox.py            # Creates 'staged' network devices from discovered MACs
    ├── check_netbox_api.py       # Validates NetBox connectivity for integration tasks
    ├── clean_stack.sh            # Maintenance and cleanup
    ├── create_users.sh           # Bulk Matrix user creation
    ├── check_env_consistency.sh  # Environment consistency checker
    ├── run_task.sh               # Docker task runner
    ├── gen_cert.sh               # SSL certificate generator
    ├── fix-nextcloud-perms.sh    # Nextcloud permission fixer
    ├── INSTALL.sh                # Installation wizard
    ├── vloot-visser.sh           # Matrix fleet backup script (deployed to backup node)
    ├── version.py                # Single Source of Truth for versioning
    ├── .env                      # Main environment configuration
    └── docker-compose.yaml       # The heart of the Sovereign Stack

---

## 4. Operational Requirements
To ensure the stability of the Sovereign Stack, the following prerequisites must be met:

* **Hardware:** Raspberry Pi 5 (8GB RAM recommended) with NVMe M.2 SSD storage.
* **Storage:** External high-capacity drive (e.g., 8TB USB) for encrypted archives.
* **Connectivity:** Tailscale for secure peer-to-peer networking between local and remote nodes.
* **Discovery:** A running NetBox instance for infrastructure documentation and IPAM.
* **Environment:** All sensitive variables must be defined in `.env`, validated by `verify_env.sh`.

---

## 5. Port Configuration
All port assignments are centralized in `.env` for easy management. See `PORT_*` variables in `.env` for the complete list.

| Service             | Port                          | Purpose               |
|---------------------|-------------------------------|-----------------------|
| Portainer           | ${PORT_PORTAINER}             | Container management  |
| AdGuard Home        | ${PORT_ADGUARD_DNS_TCP}       | DNS (TCP)             |
| AdGuard Home        | ${PORT_ADGUARD_DNS_UDP}       | DNS (UDP)             |
| AdGuard Home        | ${PORT_ADGUARD_WEB}           | Web UI                |
| AdGuard Home        | ${PORT_ADGUARD_DNS_HTTP}      | HTTP API              |
| Nginx Proxy Manager | ${PORT_NPM_HTTP}              | HTTP (Reverse Proxy)  |
| Nginx Proxy Manager | ${PORT_NPM_HTTPS}             | HTTPS (Reverse Proxy) |
| Nginx Proxy Manager | ${PORT_NPM_ADMIN}             | Admin UI              |
| Nextcloud           | ${PORT_NEXTCLOUD}             | Cloud storage         |
| NetBox              | ${PORT_NETBOX}                | IPAM/DCIM             |
| UniFi Controller    | ${PORT_UNIFI_HTTPS}           | HTTPS                 |
| UniFi Controller    | ${PORT_UNIFI_STUN}            | STUN (UDP)            |
| UniFi Controller    | ${PORT_UNIFI_API}             | API                   |
| UniFi Controller    | ${PORT_UNIFI_SSDP}            | SSDP (UDP)            |
| UniFi Controller    | ${PORT_UNIFI_GUEST_HTTPS}     | Guest HTTPS           |
| UniFi Controller    | ${PORT_UNIFI_GUEST_HTTP}      | Guest HTTP            |
| UniFi Controller    | ${PORT_UNIFI_ADOPTION}        | Adoption              |
| UniFi Controller    | ${PORT_UNIFI_SYSLOG}          | Syslog (UDP)          |
| Frigate             | ${PORT_FRIGATE_WEB}           | Web UI                |
| Frigate             | ${PORT_FRIGATE_WS}            | WebSocket             |
| Frigate             | ${PORT_FRIGATE_RTSP_RESTREAM} | RTSP Re-stream        |
| Frigate             | ${PORT_FRIGATE_RTSP}          | RTSP                  |
| Homarr              | ${PORT_HOMARR}                | Dashboard             |
| MQTT                | ${PORT_MQTT}                  | MQTT                  |
| MQTT                | ${PORT_MQTT_WS}               | WebSocket MQTT        |
| Grafana             | ${PORT_GRAFANA}               | Metrics & logging UI  |
| Loki                | ${PORT_LOKI}                  | Log aggregation       |
| Step-CA             | ${PORT_STEP_CA}               | Internal CA           |
| Coturn              | ${PORT_COTURN}                | TURN/STUN             |
| Forgejo             | ${PORT_FORGEJO_SSH}           | Git SSH               |
| Signal API          | ${PORT_SIGNAL_API}            | Signal REST           |
| Uptime Kuma         | 3001                          | Fleet monitoring      |
| Euro-Office Server  | N/A (Internal)                | Document Server (see [docs/EURO_OFFICE.md](file:///home/hvhoek/PycharmProjects/sovereign-stack/docs/EURO_OFFICE.md)) |
| Vaultwarden         | N/A (Proxied)                 | Password Manager      |
| Glances             | 61208 (Host)                  | System monitoring UI  |

---

## 6. Monitoring & Logging
The Sovereign Stack includes centralized logging and monitoring:

| Service     | Role          | Purpose                        |
|-------------|---------------|--------------------------------|
| **Grafana** | Visualization | Metrics dashboards, log viewer |
| **Loki**    | Aggregation   | Centralized log storage        |
| **Alloy**   | Collection    | Collects Docker container logs |

**Access:** Grafana is available at `http://<pi-ip>:${PORT_GRAFANA}`
**Default credentials:** `admin` + password from `.env` (GRAFANA_PASSWORD)

---

## 7. Deployment & Management
Deployment is handled through standard Docker Compose workflows, augmented by custom management scripts:

* **Installation:** Run `INSTALL.sh` to prepare the environment and check dependencies.
* **Daily Operations:** Use `backup-stack.sh` for automated maintenance and data preservation.
* **Infrastructure Mapping:** Run `infra_scanner.py` to keep NetBox updated with the latest container metadata.

---

## 8. Security Standards
Security is integrated into every layer of the stack:
* **Encrypted Storage:** AES-256 encryption for all off-site and local backup archives.
* **Access Control:** SSH key-based authentication for all remote operations.
* **Intrusion Prevention:** Fail2ban integration with real-time email notifications for blocked IPs.

---

## 9. Communication & Alerts
* **SMTP Integration:** Centralized mail configuration for Nextcloud and system alerts.
* **Real-time Notifications:** Signal Messenger API integration for mission-critical backup and security reports.
* **Secure Relays:** CoTurn (STUN/TURN) enables encrypted voice/video calls via Nextcloud Talk.
* **Collaborative Office:** Euro-Office Integration enables real-time document editing in Nextcloud (see [docs/EURO_OFFICE.md](file:///home/hvhoek/PycharmProjects/sovereign-stack/docs/EURO_OFFICE.md)).

---

## 10. Infrastructure Discovery (NetBox)
Infrastructure is managed as a "Single Source of Truth":
* **Discovery:** `infra_scanner.py` extracts image names, port mappings, and creation dates.
* **Documentation:** Detailed Markdown tables are automatically generated in NetBox for every container.

---

## 11. Architecture Decision Records (ADR)
Critical architecture changes and their rationale are documented in the `./docs/adr/` directory to ensure long-term maintainability and transparency.

---

*This documentation is part of the **Sovereign Stack** project.*
*Copyright © 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License.*
