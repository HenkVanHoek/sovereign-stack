# Sovereign Stack Technical Specification

## 1. Project-wide Requirements
* **Language**: All documentation, logs, and comments must be in English.
* **License**: All scripts must contain the full GNU GPLv3 header.
* **Formatting**: Use 4 spaces for indentation. Never use triple backticks in Markdown for code blocks.
* **Versioning**: Versioning is centralized in `version.py`. Never hardcode version numbers in script headers.
* **Code Style**: Python line length max 88 chars. Use `vi` for editing on Linux.

## 2. Execution Context: DEV vs. TARGET
To maintain system integrity, scripts and actions are segregated by environment.

| Environment | Machine | Role | Primary Tools & Scripts |
| :--- | :--- | :--- | :--- |
| **DEV** | Windows Host (PyCharm) | Development, Versioning, Git Logic | `release.ps1`, `version.py`, Git (Commit/Tag/Push) |
| **TARGET** | Linux VM (Debian/Pi OS) | Testing, Orchestration, Automation | `clean_stack.sh`, `infra_scanner.py`, `backup_stack.sh` |

## 3. Safety & Security Guards (Mandatory for Linux scripts)
* **Root Prevention**: Check if EUID is 0; exit if run as root/sudo (protects SSH identity).
* **Anti-Stacking (Flock)**: Implement kernel-level locking using `flock` to prevent concurrent execution.
* **Pre-flight Check**: Every script must call `verify_env.sh` before main execution.
* **Consistency Audit**: Use `check_env_consistency.sh` to ensure parity between `.env`, `.env.example`, and validation logic.
* **Internal Helpers**: Use `log_message` for timestamped entries and `fatal_error` for critical failures with email notification.

## 4. Core Functional Requirements
* **Inventory**: Automatically synchronize Docker services, VMs, and OctoPrint instances to NetBox via `infra_scanner.py`.
* **Database**: Export Nextcloud MariaDB dumps using `mariadb-dump`.
* **Matrix Integration**: Matrix (Synapse) is hosted externally on Intel-based hardware; integration via Reverse Proxy.
* **WOL Utility**: Use `wake_target.sh` for remote backup targets.
* **Permission Strategy**: Target scripts must use surgical `chown` (UID-specific: 33/100/999/70/1000).

## 5. Release Workflow (Hybrid Method)
* **Step 1 (DEV)**: Update the version string in `version.py` manually.
* **Step 2 (DEV)**: Perform a multiline commit via PyCharm's interface (CTRL+K).
* **Step 3 (DEV)**: Execute `release.ps1` in the PowerShell terminal to ensure the Git Tag matches `version.py`.
* **Step 4 (DEV)**: Synchronize with GitHub using `git push origin main --tags`.
* **Step 5 (TARGET)**: Run `git pull` and `git fetch --tags -f` to synchronize the local repository.

## 6. Configuration & Compliance
* **YAML Security**: Always use quotes for passwords in YAML files.
* **YAML Formatting**: Strict 2-space indentation for Docker Compose files.
* **Task Isolation**: Python-based tools must execute via `run_task.sh` wrapper in a dedicated container.
* **Environment**: All sensitive data and paths must be sourced from a `.env` file.

---
*Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0.*
