# Sovereign Stack Technical Specification

## 1. Project-wide Requirements
* **Language**: All documentation, logs, and comments must be in English.
* **License**: All scripts must contain the full GNU GPLv3 header.
* **Formatting**: Use 4 spaces for indentation. Never use triple backticks in Markdown for code blocks.
* **Markdown**: .md files must always be shown in raw text format.
* **Code Style**: Python line length max 88 chars. Use vi for editing.

## 2. Safety & Security Guards (Mandatory for every script)
* **Root Prevention**: Check if EUID is 0; exit if run as root/sudo (protects SSH identity).
* **Anti-Stacking (Flock)**: Implement kernel-level locking using 'flock' to prevent concurrent execution.
* **Pre-flight Check**: Every script must call 'verify_env.sh' before main execution.
* **Consistency Audit**: Use 'check_env_consistency.sh' to ensure parity between .env, .env.example, and validation logic.
* **Path Validation**: Explicitly verify the existence of the DOCKER_ROOT directory.
* **Internal Helpers**: Use 'log_message' for timestamped entries and 'fatal_error' for critical failures with email notification.

## 3. Core Functional Requirements (The "What")
* **Database**: Export Nextcloud MariaDB dumps using 'mariadb-dump'.
* **Matrix Integration**: Matrix (Synapse) is hosted externally on Intel-based hardware; integration via Reverse Proxy.
* **Differentiation**: Support dynamic excludes for large folders (Frigate storage, Nextcloud data).
* **WOL Utility**: Use 'wake_target.sh' with configurable retries and wait times.
* **Security**: Use OpenSSL AES-256-CBC (pbkdf2) encryption for all off-site backups.
* **Telemetry**: Capture CPU temperature and disk usage in every run.
* **Reporting**: Dispatch formatted UTF-8 reports via 'msmtp' including the last relevant log lines.
* **Remote Check**: Wake target and verify remote file presence via SSH, using OS-specific commands (Windows vs Linux).
* **Inventory**: Automatically synchronize Docker services and images to NetBox as Virtual Machines.

## 4. Detailed Script Logic (The "How")

### A. backup_stack.sh Flow
1. EUID Check -> 2. Flock lock -> 3. Source .env & verify_env.sh -> 4. DOCKER_ROOT check -> 5. Permission Pre-flight (UID 999) -> 6. DB Export -> 7. Tar with Excludes -> 8. OpenSSL Encryption -> 9. wake_target.sh -> 10. SFTP Transfer (KeepAlive) -> 11. Cleanup -> 12. Email Report.

### B. monitor_backup.sh Flow
1. EUID Check -> 2. Flock lock -> 3. Source .env & verify_env.sh -> 4. Metrics capture -> 5. Find latest .enc -> 6. Integrity test -> 7. wake_target.sh & OS-Aware Remote SSH check -> 8. Health Report.

### C. import_inventory.py Flow
1. EUID Check -> 2. Flock lock -> 3. Environment detection -> 4. verify_env.sh -> 5. Parse docker-compose.yaml -> 6. NetBox API Connect -> 7. Cluster validation -> 8. VM Update or Create -> 9. Log completion.

## 5. Configuration & Compliance
* **YAML Security**: Always use quotes for passwords in YAML files.
* **YAML Formatting**: Strict 2-space indentation for Docker Compose files.
## 5. Configuration & Compliance
* **Permission Strategy**: Scripts and manual interventions must use surgical 'chown' (UID-specific: 33/100/999/70).
* **Database Ownership**: Host directories for DB volumes must be owned by the engine's native UID (999 for MariaDB, 70 for PostgreSQL) to prevent permission drift during container restarts.* **Linter**: Scripts must pass 'yamllint' (without hyphens).
* **Environment**: All sensitive data and paths must be sourced from a .env file.
* **Logging**: Output redirected to ${DOCKER_ROOT}/backups/cron.log only AFTER lock is acquired.
* **Task Isolation**: Python-based tools must execute via 'run_task.sh' wrapper in a dedicated container.
