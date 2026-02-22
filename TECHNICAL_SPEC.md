# Sovereign Stack Technical Specification

## 1. Project-wide Requirements
* **Language**: All documentation, logs, and comments must be in English.
* **License**: All scripts must contain the full GNU GPLv3 header.
* **Formatting**: Use 4 spaces for indentation. Never use triple backticks in Markdown for code blocks.
* **Versioning**: Versioning is centralized in `version.py`. Never hardcode version numbers in script headers.
* **Code Style**: Python line length max 88 chars.

## 2. Safety & Security Guards
* **Root Prevention**: Check if EUID is 0; exit if run as root/sudo (protects SSH identity).
* **Anti-Stacking (Flock)**: Implement kernel-level locking using 'flock' to prevent concurrent execution.
* **Pre-flight Check**: Every script must call 'verify_env.sh' before main execution.
* **Consistency Audit**: Use 'check_env_consistency.sh' to ensure parity between .env and .env.example.

## 3. Core Functional Requirements
* **Inventory**: Automatically synchronize Docker services, VMs, and OctoPrint instances to NetBox via `infra_scanner.py`.
* **Database**: Export Nextcloud MariaDB dumps using 'mariadb-dump'.
* **Matrix Integration**: Matrix (Synapse) is hosted externally; integration via Reverse Proxy.

## 4. Release Workflow
### A. Windows Host (PyCharm)
* **Tool**: Use `release.ps1` (PowerShell) for automated versioning and tagging.
* **Process**: Update `version.py`, create Git tag, and push tags to origin.
### B. Linux VM (PiSelfhosting)
* **Development**: Dedicated to infrastructure testing and local Pi-specific services.

## 5. Configuration & Compliance
* **YAML Security**: Always use quotes for passwords in YAML files.
* **YAML Formatting**: Strict 2-space indentation for Docker Compose files.
* **Task Isolation**: Python-based tools must execute via 'run_task.sh' wrapper in a dedicated container.

---
*Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0.*
