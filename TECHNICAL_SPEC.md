# Sovereign Stack Technical Specification

## 1. Project-wide Requirements
* **Language**: All documentation, logs, and comments must be in English.
* **License**: All scripts must contain the full GNU GPLv3 header.
* **Formatting**: Use 4 spaces for indentation. Never use triple backticks in Markdown for code blocks.
* **Versioning**: Versioning is centralized in `version.py`. Never hardcode version numbers in script headers.
* **Markdown**: .md files must always be shown in raw text format.
* **Code Style**: Python line length max 88 chars. Use vi for editing.

## 2. Safety & Security Guards (Mandatory for every script)
* **Root Prevention**: Check if EUID is 0; exit if run as root/sudo (protects SSH identity).
* **Anti-Stacking (Flock)**: Implement kernel-level locking using 'flock'.
* **Pre-flight Check**: Every script must call 'verify_env.sh' before main execution.
* **Consistency Audit**: Use 'check_env_consistency.sh' to ensure parity between .env and .env.example.

## 3. Core Functional Requirements
* **Database**: Export Nextcloud MariaDB dumps using 'mariadb-dump'.
- **Matrix Integration**: Matrix (Synapse) is hosted externally; integration via Reverse Proxy.
* **WOL Utility**: Use 'wake_target.sh' for remote backup targets.
* **Infrastructure Discovery**: Automatically synchronize Docker services, VirtualBox VMs, and OctoPrint instances to NetBox via `infra_scanner.py`.

## 4. Configuration & Compliance
* **YAML Security**: Always use quotes for passwords in YAML files.
* **Permission Strategy**: Use surgical 'chown' (UID-specific: 33/100/999/70/1000).
* **Task Isolation**: Python-based tools must execute via `run_task.sh` wrapper in a dedicated container.
