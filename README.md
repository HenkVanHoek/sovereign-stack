# sovereign-stack: The Sovereign Blueprint

# sovereign-stack: The Sovereign Blueprint

The **sovereign-stack** is a comprehensive infrastructure project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. This is not just a collection of scripts, but a robust, privacy-first blueprint designed for those who believe that data sovereignty is a fundamental human right in an age of centralized cloud dominance.

### Beyond the Cloud
In an era where "the cloud" is simply someone else's computer, the Sovereign Stack provides a proven path to transition away from proprietary, centralized ecosystems like **Microsoft 365** or **Google Workspace** and or **Whatsapp**. By deploying this blueprint, you move your digital life—from file management with **Nextcloud** to decentralized communication via **Matrix**—back within your own physical walls, under your own terms.

### Engineering for Reliability
Building on decades of software engineering experience—from the early days of Delphi and ISDN-based systems to modern containerized environments—this stack emphasizes stability, security, and the "Single Source of Truth" philosophy. Through automated infrastructure discovery and strict operational standards, the Sovereign Stack ensures that your self-hosted environment is as reliable and professional as any commercial enterprise solution.

> **Current Version:** v4.3.0 (See [version.py](./version.py) for the Single Source of Truth).---

## 1. Core Vision & Philosophy
* **Autonomy:** Reducing dependency on centralized "Big Tech" clouds.
* **Privacy:** Keeping community and personal data within your own physical walls.
* **Discovery:** Automated infrastructure mapping to ensure your asset inventory is always accurate.

---

## 2. The Sovereign Service Suite
The stack is a curated collection of services, optimized to run harmoniously on the Raspberry Pi 5.

### Core Infrastructure & Asset Management
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **[Nextcloud](https://nextcloud.com/)** | Cloud Hub | File sync, contacts, calendar, and collaborative office. |
| **[NetBox](https://netboxlabs.com/)** | IPAM & DCIM | **Single Source of Truth:** Manages IP addresses, VMs, and device racking. |
| **[Infra Scanner]** | Discovery | **v4.3.0:** Automated SSH-based discovery of VirtualBox VMs and Docker containers with NetBox synchronization. |
| **[Nginx Proxy Manager]** | Reverse Proxy | Manages SSL and secure traffic routing for internal/external nodes. |

### Specialized & Home Services
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **[Home Assistant]** | Automation Core | Local control of IoT devices and energy management. |
| **[Frigate]** | NVR / AI | Real-time local object detection for CCTV. |
| **[OctoPrint]** | 3D Printing | Native discovery support with HTML title verification to prevent false positives. |
| **[AdGuard Home]** | DNS & Ad-block | Network-wide privacy-focused DNS (DoH/DoT). |

---

## 3. Project Structure (v4.3.0 Updates)

| File / Directory | Purpose |
| :--- | :--- |
| `version.py` | **Central Versioning:** The primary version declaration for the entire stack. |
| `infra_scanner.py` | **Discovery Engine:** SSH-based scanner for VirtualBox and Docker inventory. |
| `Dockerfile.infra_scanner` | **Containerized Scanner:** Runs the discovery engine within the Sovereign network. |
| `inventory.json` | Template for host metadata (Mapping hosts to specific NetBox clusters). |
| `credentials.json` | Template for SSH authentication secrets. |
| `check_env_consistency.sh` | **Audit Tool:** Ensures parity between .env, .env.example, and validation logic. |

---

## 4. Operational Standards
To maintain stability across the Sovereign ecosystem, we adhere to strict standards:

1.  **Versioning:** Never hardcode version numbers in script headers; always import from `version.py`.
2.  **YAML/JSON Formatting:** Use **double quotes** for all passwords.
3.  **Python Standards:** The line length of Python code should not exceed **88 characters**.
4.  **Separation of Concerns:** Keep host metadata in `inventory.json` and secrets in `credentials.json`.
5.  **Documentation:** Documentation pages should be in **English** for GitHub publication.

---

## 5. Safety Guards (Sovereign Security)
* **The Gatekeeper:** `verify_env.sh` validates all mandatory environment variables before any service starts.
* **Active Defense:** **Fail2ban** is used to protect the stack against brute-force attacks.
* **Environment Guard:** `check_env_consistency.sh` prevents "variable drift" between example files and live settings.

---

## 6. Infrastructure Discovery (Infra Scanner)
The **Infra Scanner** (v4.3.0) is a key component of the Sovereign Stack that ensures your NetBox "Source of Truth" reflects reality:
* **Automated Sync:** Connects to hosts via SSH to find VirtualBox VMs and Docker containers.
* **Detailed Metadata:** Automatically extracts Docker image names, creation dates, and port mappings.
* **NetBox Integration:** Synchronizes data with NetBox, using custom cluster mappings (e.g., `Cluster-Sovereign-Pi`) to maintain database consistency.
* **Markdown Reports:** Generates rich, readable comments in NetBox for every discovered container.

---

*This documentation is part of the **Sovereign Stack** project.
Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
