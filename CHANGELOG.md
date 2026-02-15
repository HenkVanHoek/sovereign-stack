# Changelog

All notable changes to the Sovereign Stack project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
