# Changelog

All notable changes to the Sovereign Stack project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## [4.3.0] - 2026-02-23
### Added
- **Docker Metadata Discovery:** The Infra Scanner now extracts container image names, creation dates, and port mappings via SSH.
- **Rich NetBox Integration:** Containers are now synchronized to NetBox as Virtual Machines within dedicated Docker clusters.
- **Markdown Documentation:** Automated generation of detailed Markdown tables in NetBox comments for each container.
- **Cluster Mapping:** Intelligent mapping of hosts to existing NetBox clusters (e.g., `Cluster-Sovereign-Pi`).
- **English Documentation:** Updated the main README.md and code comments to English for GitHub publication standards.

### Changed
- **Enhanced OctoPrint Verification:** Improved HTML title checks to prevent false-positive detection on proxy and NVR services.
- **Network Logic:** Migrated the Infra Scanner to the `pi-services` Docker network for direct internal API access to NetBox.

### Fixed
- **API Endpoint Error:** Resolved the `'Endpoint' object has no attribute 'cluster_types'` error by correcting the pynetbox virtualization path.
- **Resource Busy Error:** Fixed issues where `.env` files were locked during `docker cp` operations by utilizing native Docker volumes and environment loading.

---
## [4.2.0] - 2026-02-22 "The Discovery Update"

### Added
- **Infrastructure Discovery**: Added `infra_scanner.py` for automated SSH-based inventory of Docker containers and VirtualBox VMs.
- **Service Intelligence**: Implemented detection for **OctoPrint** 3D-printer interfaces.
- **Asset Management**: Full integration of **NetBox** with supporting scripts (`seed_netbox.py`, `import_inventory.py`, `check_netbox_api.py`).
- **Project Standards**: Introduced `version.py` for centralized versioning and `.editorconfig` for Python linting rules.
- **Tooling**: Added `run_task.sh` and `bulk_rename_from_nmap.py` for administrative efficiency.

### Changed
- **Architecture Refactor**: Separated metadata from secrets by splitting `inventory.json` and `credentials.json`.
- **Matrix Strategy**: Migrated from local Conduit to external Synapse hosting via Reverse Proxy.
- **Build System**: Switched to **uv** in `Dockerfile.infra_scanner` for near-instant dependency installation.
- **Environment Audit**: Expanded `verify_env.sh` to validate 56 variables; added `check_env_consistency.sh`.
- **Code Quality**: Refactored Python scripts to resolve scope-shadowing and linter warnings in PyCharm.

### Fixed
- Fixed regression where network variables were lost during the removal of Conduit.
- Optimized `backup_stack.sh` with full headers and linter improvements.

### Removed
- **Matrix**: Removed local Conduit (Matrix) services and associated data persistence layers.

---
## [4.1.0] - 2026-02-19 "Infrastructure Expansion"

### Added
- **Infrastructure Management**: Integrated **Netbox** (IPAM & DCIM) to manage IP addresses, virtual machines, and device racking.
- **Database**: Added a dedicated **PostgreSQL 15** container specifically for the Netbox backend.
- **Caching**: Added a dedicated **Redis 7** container for Netbox task queuing and caching.

### Changed
- **Documentation**: Updated `README.md`, `First-Run Guide.md`, `Checklist.md`, and `INSTALL.md` to reflect the new Netbox requirements and initialization commands.
-
## [4.0.0] - 2026-02-15 "The Sovereign Awakening"

### Added
- **Communication**: Replaced Prosody (XMPP) with **Matrix (Conduit)** for modern, federated messaging.
- **Home Automation**: Added **Home Assistant Core**, **Mosquitto** (MQTT), and **Frigate** (NVR/AI).
- **Office Suite**: Integrated **Collabora Online** for real-time document editing in Nextcloud.
- **Performance**: Added **Nextcloud Notify Push** (High Performance Backend).
- **Management**: Added **Portainer** for container visualization and management.
- **Networking**: Added specific `.env` variables for split-DNS (`EXTERNAL_DNS_IP`, `EXTERNAL_DNS_NAME`, `INTERNAL_HOST_IP`).

### Changed
- **Breaking**: Complete overhaul of `docker-compose.yaml` to strict **2-space indentation** and quoted passwords.
- **Breaking**: `.env` structure changed; legacy DNS variables deprecated.
- **Security**: Adopted a "Surgical Permission" model. Scripts now avoid broad `chown -R` commands and target specific UID/GIDs (33, 100, 999).
- **Documentation**: `README.md` and manual rewritten to English with detailed service enumeration (19+ services).

### Fixed
- Fixed Docker container name conflicts ("ghost containers") during restarts.
- Fixed `restore_stack.sh` permissions logic to include Matrix (UID 100) and Database (UID 999) folders.

---

## [3.6.1] - 2026-01-25

### Added
- New security guard script: `verify_env.sh` to ensure all mandatory secrets are present before execution.
- Implementation of `flock` (file locking) in all automation scripts to prevent overlapping processes.
- Full support for `ed25519` SSH keys for faster and more secure remote authentication.
- Added Visual Studio Code (`.vscode`) and PyCharm (`.idea`) exclusions to `.gitignore`.
- Integrated `wakeonlan` check in `INSTALL.sh` for remote backup target wake-up capability.
- Added `COTUR_SECRET` auto-generation for secure Nextcloud Talk video calls.

### Changed
- Standardized project directory structure to `~/sovereign-stack` for better GitHub portability.
- Refactored `INSTALL.sh` into a professional wizard with dependency checks and environment setup.
- Optimized Cron schedule: Backup at 03:00 and Monitor at 03:30 to fit the 90-minute integrity window.
- Updated all documentation (INSTALL, README, etc.) to English for the public GitHub release.
- Switched all script headers to the full GNU General Public License v3.0 text.

### Fixed
- Fixed pathing issues in `monitor_backup.sh` when communicating with Windows-based backup targets.
- Replaced Linux `test -e` commands with Windows-compatible `if exist` logic for remote file verification.
- Removed redundant `2>&1` redirects in Crontab to ensure cleaner and more specific log files.
- Corrected file permission issues by adding a dedicated `fix-nextcloud-perms.sh` utility.

### Security
- Prevented scripts from running as `root` to adhere to the principle of least privilege.
- Hardened `.env` file permissions to `600` automatically during installation.
- Enhanced `.gitignore` to prevent accidental commits of certificates (`.crt`, `.key`) and database dumps (`.sql`).

---

## [3.5.0] - 2026-01-11

### Added
- Initial support for NVMe M.2 SSD storage on Raspberry Pi 5.
- Migration from SD-card based storage to high-performance disk setup.
- Basic automated backup script for the Docker stack.

---

### Note on Versioning History

The Sovereign Stack began as a personal hobby and laboratory project to achieve digital autonomy. Versions prior to **v3.5.0** were part of an internal, rapid-development phase and are not individually documented here.

Starting with **v3.6.1**, the project has transitioned to a structured release cycle for public use on GitHub, with all future changes being meticulously tracked in this log.

---

*This documentation is part of the **Sovereign Stack** project.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
