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
* **Path Validation**: Explicitly verify the existence of the DOCKER_ROOT directory.
* **Internal Helpers**: Use 'log_message' for timestamped entries and 'fatal_error' for critical failures with email notification.

## 3. Core Functional Requirements (The "What")
* **Database**: Export Nextcloud MariaDB dumps using 'docker exec' and 'mariadb-dump'.
* **Differentiation**: Support dynamic excludes for large folders (Frigate storage, Nextcloud data).
* **WOL Utility**: Use 'wake_target.sh' with configurable retries and wait times.
* **Security**: Use OpenSSL AES-256-CBC (pbkdf2) encryption for all off-site backups.
* **Telemetry**: Capture CPU temperature and disk usage in every run.
* **Reporting**: Dispatch formatted UTF-8 reports via 'msmtp' including the last relevant log lines.
* **Remote Check**: Wake target and verify remote file presence via SSH, using OS-specific commands (Windows vs Linux)

## 4. Detailed Script Logic (The "How")

### A. backup_stack.sh Flow
1. EUID Check → 2. Flock lock (/tmp/sovereign_backup.lock) → 3. Source .env & verify_env.sh → 4. DOCKER_ROOT check → 5. DB Export → 6. Tar with Excludes → 7. OpenSSL Encryption → 8. wake_target.sh → 9. SFTP Transfer → 10. Cleanup (>${BACKUP_RETENTION_DAYS}) → 11. Email Report.
### B. monitor_backup.sh Flow
1. EUID Check → 2. Flock lock (/tmp/sovereign_monitor.lock) → 3. Source .env & verify_env.sh → 4. Metrics capture → 5. Find latest .enc → 6. Integrity test (decrypt to /dev/null) → 7. wake_target.sh & OS-Aware Remote SSH check → 8. Health Report.

## 5. Configuration & Compliance
* **YAML Security**: Always use quotes for passwords in YAML files.
* **Linter**: Scripts must pass 'yamllint' (without hyphens).
* **Environment**: All sensitive data and paths must be sourced from a .env file.
* **Logging**: Output redirected to ${DOCKER_ROOT}/backups/cron.log only AFTER lock is acquired.

---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
