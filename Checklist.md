# Deployment Verification Checklist (v4.2.1)

Perform these checks to ensure autonomy, resilience, and proper synchronization between the Windows Host and the Linux Target environment.

## 1. Release & Synchronization (Context: Windows Host / DEV)
- [ ] **Context Check**: Am I in the PyCharm PowerShell terminal?
- [ ] **CRITICAL: Version Update**: Manually update the version string in `version.py` to "4.2.1".
- [ ] **Documentation**: Ensure `MAINTENANCE.md` and `TECHNICAL_SPEC.md` reflect v4.2.1 changes.
- [ ] **Atomic Commit**: Perform a multiline commit in PyCharm (`CTRL+K`) including all changed files.
- [ ] **Tagging**: Run `.\release.ps1` to create the local Git Tag matching the new version in `version.py`.
- [ ] **GitHub Sync**: Execute `git push origin main --tags` to update the remote repository.

## 2. Environment & Connectivity (Context: Linux VM / TARGET)
- [ ] **Context Check**: Am I in the Linux Bash terminal?
- [ ] **Git Sync**: Run `git pull` followed by `git fetch --tags -f` to synchronize tags and code.
- [ ] **Secrets**: Verify `.env` exists and contains no `<REPLACE_WITH...>` placeholders.
- [ ] **Consistency**: Run `./check_env_consistency.sh` to validate all environment variables.
- [ ] **Permissions**: Run `chmod +x ./*.sh` and ensure surgical UID ownership (33/100/999/70/1000).
- [ ] **Remote Link**: Run `./test_remote_connection.sh` to verify WoL and SSH access to backup targets.
- [ ] **Internal Trust**: Generate at least one certificate via `./gen_cert.sh` to test Step-CA.

## 3. Infrastructure Discovery (v4.2.x)
- [ ] **Inventory Split**: Confirm `inventory.json` (metadata) and `credentials.json` (secrets) are present.
- [ ] **NetBox Init**: Run `seed_netbox.py` to initialize default Sovereign Stack types.
- [ ] **Scanner Build**: Verify the `infra-scanner` container builds successfully (using `uv`).
- [ ] **First Scan**: Perform a manual scan and verify that Docker containers and VMs appear in NetBox.
- [ ] **OctoPrint**: Confirm active OctoPrint instances are detected by the scanner.

## 4. Service Orchestration & Monitoring
- [ ] **Stack Boot**: Run `docker compose up -d` and check for "Exit 1" containers.
- [ ] **Log Audit**: Check `docker logs fail2ban` to ensure security jails are active.
- [ ] **Nextcloud Data**: Run `./fix-nextcloud-perms.sh` if data access issues occur after updates.
- [ ] **SMTP Pipe**: Test mail connectivity via `msmtp` to your freedom.nl relay.
- [ ] **Dashboard**: Verify all services (including NetBox and Scanner status) are correct in Homarr.

## 5. Disaster Recovery Preparation
- [ ] **Manual Backup**: Run `./backup_stack.sh` and verify the archive creation.
- [ ] **Integrity**: Validate the AES-256-CBC encryption of the backup archive.
- [ ] **Monitoring**: Confirm that `monitor_backup.sh` is correctly set in the crontab.

---
*This document is part of the Sovereign Stack project. Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0.*
