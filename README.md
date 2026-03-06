# sovereign-stack: The Sovereign Blueprint

The **sovereign-stack** is a comprehensive infrastructure project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. This is not just a collection of scripts, but a robust, privacy-first blueprint designed for those who believe that data sovereignty is a fundamental human right in an age of centralized cloud dominance.

### Beyond the Cloud
In an era where "the cloud" is simply someone else's computer, the Sovereign Stack provides a proven path to transition away from proprietary, centralized ecosystems like **Microsoft 365**, **Google Workspace**, or **WhatsApp**. By deploying this blueprint, you move your digital life back within your own physical walls, under your own terms.

### Engineering for Reliability
Building on decades of software engineering experience, this stack emphasizes stability, security, and the "Single Source of Truth" philosophy. Through automated infrastructure discovery and strict operational standards, the Sovereign Stack ensures that your self-hosted environment is as reliable and professional as any commercial enterprise solution.

> **Current Version:** v4.3.0 (See version.py (./version.py) for the Single Source of Truth).

---

## 1. Core Vision & Philosophy
* **Autonomy:** Reducing dependency on centralized "Big Tech" clouds.
* **Privacy:** Keeping personal and community data within your own physical walls.
* **Discovery:** Automated infrastructure mapping via NetBox to ensure your asset inventory is always accurate.
* **Integrity:** Multi-stage environment validation (The Sentinel) to ensure stack stability.

---

## 2. The Sovereign Service Suite (v4.3.0)
The stack is a curated collection of services, optimized for the Raspberry Pi 5 (8GB).

### Core Infrastructure & Data Sovereignty
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **Nextcloud** | Cloud Hub | File sync, contacts, calendar, and collaborative office. |
| **NetBox** | SSoT | **Single Source of Truth:** IPAM and DCIM for all assets. |
| **Infra Scanner** | Discovery | Automated discovery of Docker containers and VMs. |
| **Forgejo** | Git Hosting | Sovereign code collaboration and repository management. |
| **S3 Snapshots** | Redundant Storage | Distributed off-site storage for CCTV media (Garage S3). |
| **Nginx Proxy Manager**| Reverse Proxy | Secure traffic routing (Ports 80/443/5222/5269). |

### Communication & Home Services
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **Homarr** | Dashboard | Modern entry point for all services (Replacing Dashy). |
| **Signal-API** | Bridge | Secure gateway to the Signal messaging protocol. |
| **Home Assistant** | Automation | Local control of IoT devices and energy management. |
| **Frigate** | NVR / AI | Real-time object detection for CCTV. |
| **AdGuard Home** | DNS | Network-wide privacy-focused DNS (DoH/DoT). |
| **UniFi Controller** | Network | Local management of Ubiquiti network hardware. |

---

## 3. Modularity: Customizing your Stack
The Sovereign Stack is designed to be modular. You can tailor the services to your needs:

* **Disabling Services:** To disable a service (e.g., Matrix or Forgejo), simply comment out the service block in docker-compose.yaml. The env-validator only enforces variables for active services.
* **Running without S3 Storage:**
    1. Comment out the s3-mount-fixer service in docker-compose.yaml.
    2. Remove s3-mount-fixer from the depends_on list in the Frigate service.
    3. Map Frigate snapshots to a local directory instead of ${S3_SNAPSHOTS_MOUNT_PATH}.

---

## 4. Project Structure (v4.3.0)

| File / Directory | Purpose |
| :--- | :--- |
| version.py | **Central Versioning:** The primary version declaration. |
| infra_scanner.py | **Discovery Engine:** SSH-based scanner for inventory. |
| import_inventory.py | **NetBox Sync:** Synchronizes scan data to NetBox. |
| inventory.json | **Asset Metadata:** Maps physical hosts to NetBox clusters. |
| etc/systemd/ | Templates for system-level services (S3 Rclone mounts). |
| scripts/verify_env.sh | **The Sentinel:** Validates the entire environment before boot. |

---

## 5. Operational Standards
1. **Versioning:** Import version numbers from version.py.
2. **YAML Syntax:** Use dictionary-style KEY: VALUE for environment variables.
3. **Timezones:** Every service must utilize the ${TZ} variable for log synchronization.
4. **Update Management:** Databases and core services must use the watchtower.enable=false label.
5. **Security Formatting:** Use **double quotes** for all passwords and secrets in YAML/JSON.
6. **Documentation:** All documentation, logs, and comments must be in **English**.
7. **Storage Abstraction:** Use S3-compatible APIs for critical snapshots with automated UID/GID fixing via s3-mount-fixer.

---

## 6. Security & Integrity Guardians
The stack employs a multi-stage startup sequence:

* **The Sentinel (Env Validator):** Audits all mandatory variables (including SMTP and S3 settings) and performs an expansion audit.
* **The Janitor (Permission Fixer):** Ensures FUSE mounts have correct permissions for Docker access.
* **Active Defense:** **Fail2ban** protects the stack with real-time email notifications for blocked IPs.

---

## 7. Communication & Alerts
* **SMTP Integration:** Centralized mail configuration for Nextcloud and system alerts (Fail2ban/Backup reports).
* **Real-time Notifications:** **Notify-push** provides high-performance instant updates for mobile clients.
* **Secure Relays:** **CoTurn** (STUN/TURN) enables encrypted voice/video calls via Nextcloud Talk.

---

## 8. Infrastructure Discovery (NetBox)
Infrastructure is managed as a "Single Source of Truth":
* **Discovery:** infra_scanner.py extracts image names, port mappings, and creation dates.
* **Documentation:** Detailed Markdown tables are automatically generated in NetBox for every container.
* **Decisions:** See ADR 0002 (./docs/adr/0002-infrastructure-discovery.md) for the architecture behind this implementation.

---

## 9. Architecture Decision Records (ADR)
This project follows a structured decision-making process. Critical architecture changes and their rationale are documented here:
* **ADR 0001:** Removal of Matrix Conduit as a local home server (Location: docs/adr/0001-removal-of-matrix-conduit.md)
* **ADR 0002:** Implementation of NetBox and S3 Abstraction (Location: docs/adr/0002-infrastructure-discovery.md)
* **ADR 0003:** Docker Image Tagging and Update Strategy (Location: docs/adr/0003-docker-image-versioning.md)

---

*This documentation is part of the **Sovereign Stack** project.
Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License (LICENSE).*
