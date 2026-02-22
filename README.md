# sovereign-stack: The Sovereign Blueprint

The **sovereign-stack** is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It is a robust, privacy-first infrastructure blueprint designed for those who believe that data sovereignty is a fundamental right.

This stack is a **complete replacement for proprietary ecosystems**. By deploying this blueprint, you can replace centralized communication tools with your own **Matrix (Synapse)** infrastructure (hosted externally), and transition away from **Microsoft 365** or **Google Workspace** by utilizing **Nextcloud** with **Collabora Online**.

> **Current Version:** v4.2.0 (See [version.py](./version.py) for the Single Source of Truth).

---

## 1. Core Vision & Philosophy
* **Autonomy:** Reducing dependency on centralized "Big Tech" clouds.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **Discovery:** Automated infrastructure mapping to ensure your asset inventory is always accurate.

---

## 2. The Sovereign Service Suite
The stack is a curated collection of services, optimized to run harmoniously on the Raspberry Pi 5.

### Core Infrastructure & Asset Management
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **[Nextcloud](https://nextcloud.com/)** | Cloud Hub | File sync, contacts, calendar, and collaborative office. |
| **[NetBox](https://netboxlabs.com/)** | IPAM & DCIM | **Single Source of Truth:** Manages IP addresses, VMs, and device racking. |
| **[Infra Scanner]** | Discovery | **New in v4.2.0:** Automated SSH-based discovery of Docker containers, VMs, and OctoPrint. |
| **[Nginx Proxy Manager]** | Reverse Proxy | Manages SSL and secure traffic routing for internal/external nodes. |

### Specialized & Home Services
| Service | Role | Purpose |
| :--- | :--- | :--- |
| **[Home Assistant]** | Automation Core | Local control of IoT devices and energy management. |
| **[Frigate]** | NVR / AI | Real-time local object detection for CCTV. |
| **[OctoPrint]** | 3D Printing | Native discovery support for 3D printer fleet management. |
| **[AdGuard Home]** | DNS & Ad-block | Network-wide privacy-focused DNS (DoH/DoT). |

---

## 3. Project Structure (v4.2.0 Additions)

| File / Directory | Purpose |
| :--- | :--- |
| `version.py` | **Central Versioning:** The primary version declaration for the entire stack. |
| `infra_scanner.py` | **Discovery Engine:** SSH-based scanner for infrastructure inventory. |
| `Dockerfile.infra_scanner` | **High-Speed Build:** Uses `uv` for near-instant Python dependency management. |
| `inventory.json.example` | Template for your host metadata and multiline comments. |
| `credentials.json.example` | Template for SSH authentication secrets (Separated from metadata). |
| `check_env_consistency.sh` | **Audit Tool:** Ensures parity between .env, .env.example, and validation logic. |
| `seed_netbox.py` | Utility to initialize NetBox with default Sovereign Stack types. |

---

## 4. Operational Standards
To maintain stability across the 40+ devices in the Sovereign ecosystem, we adhere to strict standards:

1.  **Versioning:** Never hardcode version numbers in script headers; always import from `version.py`.
2.  **YAML Formatting:** Use **2 spaces** for indentation and **double quotes** for all passwords.
3.  **Python Linting:** Code must follow `.editorconfig` rules, including an **88-character** maximum line length.
4.  **Separation of Concerns:** Keep host metadata in `inventory.json` and secrets in `credentials.json`.

---

## 5. Safety Guards (Sovereign Security)
* **The Gatekeeper:** `verify_env.sh` validates all 56 mandatory environment variables before any service starts.
* **Active Defense:** **Fail2ban** is reactivated to protect the stack against brute-force attacks.
* **Environment Guard:** `check_env_consistency.sh` prevents "variable drift" between example files and live settings.

---

*This documentation is part of the **Sovereign Stack** project.
Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
