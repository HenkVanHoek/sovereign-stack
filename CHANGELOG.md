# Changelog

All notable changes to the Sovereign Stack project will be documented in this file.
The format is based on Keep a Changelog (https://keepachangelog.com/en/1.1.0/),
and this project adheres to Semantic Versioning (https://semver.org/spec/v2.0.0.html).

## [4.5.0] - 2026-03-18
### Added
- **3-2-1 Backup Strategy:** Implemented comprehensive backup strategy with local USB and off-site NAS targets.
- **Wake-on-LAN Support:** Added WoL for off-site backup targets via `BACKUP_OFFSITE_WOL` configuration.
- **Checksum Verification:** Replaced file download verification with SHA256 checksum comparison for efficiency.
- **Retention Settings:** Added configurable retention for both local (`BACKUP_LOCAL_RETENTION_DAYS`) and off-site (`BACKUP_OFFSITE_RETENTION_VERSIONS`) backups.

### Changed
- **Consolidated Configuration:** Merged `.backup.env` into `.env` for simplified management.
- **Renamed Variables:** All backup variables now use consistent naming:
  - `BACKUP_LOCAL_*` for USB/local backup settings
  - `BACKUP_OFFSITE_*` for NAS/remote backup settings
  - `BACKUP_ENCRYPTION_KEY` (was `BACKUP_PASSWORD`/`DB_PASSWORD`)
- **Enhanced Monitoring:** Monitor script now reports ✅/⚠️/❌ status based on actual verification results.

### Fixed
- **Monitor Script:** Fixed undefined variable errors, corrected backup directory paths.
- **WoL Scripts:** Added `USER` variable fallback for cron compatibility.
- **SSH/SFTP Issues:** Backup now uses `cat` over SSH instead of SCP to work with NAS devices without SFTP.

---

## [4.4.0] - 2026-03-13
### Added
- **Remote VM Backup:** Implemented a robust rsync-based backup system for remote Synapse (Matrix) VMs via Tailscale.
- **Automated DB Dumps:** Integrated non-interactive `pg_dumpall` execution inside remote Docker containers using `PGPASSWORD` injection.
- **Enhanced Signal Alerts:** Added real-time Signal Messenger notifications for backup start, success, and failure, including session metadata.
- **Smart Retention:** Added a 7-day rolling window for SQL dumps and automated log rotation (1000-line limit) to prevent storage bloat.
- **Security Elevation:** Implemented `--rsync-path="sudo rsync"` logic to allow secure backup of root-owned files (like Synapse signing keys) without interactive passwords.

### Changed
- **Logging Architecture:** Overhauled the log format with clear session headers, timestamps, and destination path reporting for better auditability.
- **Variable-Driven Design:** Decoupled project paths by moving `DOCKER_FOLDER` and `PROJECT_ROOT` to `.backup.env` for better portability.
- **Version Integration:** The backup script now dynamically pulls the current version from `version.py` for inclusion in alerts and logs.

### Fixed
- **Host Key Failures:** Resolved "Host key verification failed" errors by adding `StrictHostKeyChecking=accept-new` to automated SSH commands.
- **Permission Denied Errors:** Fixed rsync failures on sensitive local files (Traefik `acme.json`, Mosquitto DB) by utilizing elevated execution logic.
- **Logic Resilience:** Replaced `docker compose exec` with direct `docker exec` in backup routines to bypass directory context issues on remote hosts.

---

## [4.3.0] - 2026-02-23
### Added
- **Docker Metadata Discovery:** The Infra Scanner now extracts container image names, creation dates, and port mappings via SSH.
- **Rich NetBox Integration:** Containers are now synchronized to NetBox as Virtual Machines within dedicated Docker clusters.
- **Markdown Documentation:** Automated generation of detailed Markdown tables in NetBox comments for each container.
- **Cluster Mapping:** Intelligent mapping of hosts to existing NetBox clusters (e.g., Cluster-Sovereign-Pi).
- **English Documentation:** Updated the main README.md and code comments to English for GitHub publication standards.
- **S3 Storage Abstraction:** Added support for Garage S3 and Rclone FUSE mounts for off-site data resilience.
- **New Services:** Forgejo (Git), Homarr (Dashboard), Signal-API, UniFi Controller, and CoTurn (STUN/TURN).
- **Security Guardians:** Introduced the env-validator (The Sentinel) and s3-mount-fixer (The Janitor).
- **Email Integration:** Full SMTP support for Nextcloud and Fail2ban real-time alerts.

---

## [3.5.0] - 2026-01-11
### Added
- Initial support for NVMe M.2 SSD storage on Raspberry Pi 5.
- Migration from SD-card based storage to high-performance disk setup.
- Basic automated backup script for the Docker stack.

---

### Note on Versioning History

The Sovereign Stack began as a personal hobby and laboratory project to achieve digital autonomy. Versions prior to **v3.5.0** were part of an internal, rapid-development phase and are not individually documented here.

Starting with **v4.4.0**, the project continues its transition to a structured release cycle for public use on GitHub, with all future changes being meticulously tracked in this log.

---

*This documentation is part of the **Sovereign Stack** project.
Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License (LICENSE).*
