# Deployment Verification Checklist (v4.3.1)

Perform these checks to ensure autonomy, resilience, and proper synchronization between the Windows Host and the Linux Target environment.

## 1. Release & Synchronization (Context: Windows Host / DEV)
- <span style="font-size: 2em;">☐</span> **Linter Check**: Does the PyCharm Analysis widget show a green checkmark (no errors/warnings) for all modified files?
- <span style="font-size: 2em;">☐</span> **Context Check**: Am I in the PyCharm PowerShell terminal?
- <span style="font-size: 2em;">☐</span> **CRITICAL: Version Update**: Ensure version.py is manually updated to the new release string (e.g., "4.3.1").
- <span style="font-size: 2em;">☐</span> **Documentation**: Ensure CHANGELOG.md, INSTALL.md, and TECHNICAL_SPEC.md reflect current changes.
- <span style="font-size: 2em;">☐</span> **ADR Verification**: Ensure all new ADRs (0002, 0003) are correctly documented in docs/adr/.
- <span style="font-size: 2em;">☐</span> **Pre-commit Hooks**: Ensure all hooks pass before final push.
- <span style="font-size: 2em;">☐</span> **Atomic Commit**: Perform a multiline commit in PyCharm (CTRL+K) including all changed files.
- <span style="font-size: 2em;">☐</span> **Tagging**: Run .\release.ps1 to create the local Git Tag matching the version in version.py.
- <span style="font-size: 2em;">☐</span> **GitHub Sync**: Execute git push origin main --tags to update the remote repository.

## 2. Environment & Connectivity (Context: Linux VM / TARGET)
- <span style="font-size: 2em;">☐</span> **Context Check**: Am I in the Linux Bash terminal?
- <span style="font-size: 2em;">☐</span> **Git Sync**: Run git pull followed by git fetch --tags -f to synchronize tags and code.
- <span style="font-size: 2em;">☐</span> **No Local Changes**: Run git status to ensure the Linux target has no uncommitted local overrides.
- <span style="font-size: 2em;">☐</span> **Secrets**: Verify .env exists and contains no <REPLACE_WITH...> placeholders.
- <span style="font-size: 2em;">☐</span> **Consistency**: Run ./check_env_consistency.sh to validate all environment variables.
- <span style="font-size: 2em;">☐</span> **YAML Standard**: Verify docker-compose.yaml uses dictionary-style KEY: "VALUE" syntax.
- <span style="font-size: 2em;">☐</span> **Permissions**: Run chmod +x ./*.sh and ensure surgical UID ownership (33/100/999/70/1000).

## 3. Infrastructure Discovery
- <span style="font-size: 2em;">☐</span> **Inventory Split**: Confirm inventory.json (metadata) and credentials.json (secrets) are present.
- <span style="font-size: 2em;">☐</span> **Scanner Build**: Verify the infra-scanner container builds successfully (using uv).
- <span style="font-size: 2em;">☐</span> **First Scan**: Run ./run_task.sh python3 infra_scanner.py and import_inventory.py.
- <span style="font-size: 2em;">☐</span> **NetBox Validation**: Verify that Docker containers and VMs appear correctly in NetBox clusters.

## 4. Service Orchestration & Monitoring
- <span style="font-size: 2em;">☐</span> **Stack Boot**: Run docker compose up -d and check for "Exit 1" containers.
- <span style="font-size: 2em;">☐</span> **The Janitor (S3)**: Check s3-mount-fixer logs to confirm UID/GID ownership on FUSE mounts is correct.
- <span style="font-size: 2em;">☐</span> **Watchtower**: Confirm database-driven containers have watchtower.enable=false labels.
- <span style="font-size: 2em;">☐</span> **DNS Split-Horizon**: Verify AdGuard Home DNS Rewrites point to the internal Pi IP.
- <span style="font-size: 2em;">☐</span> **SMTP Pipe**: Test host-level mail connectivity via msmtp to the freedom.nl relay.
- <span style="font-size: 2em;">☐</span> **Dashboard**: Verify all core services are active and reachable via Homarr.

## 5. Disaster Recovery Preparation
- <span style="font-size: 2em;">☐</span> **Remote Link**: Run ./test_remote_connection.sh to verify WoL and SSH access to Windows backup targets.
- <span style="font-size: 2em;">☐</span> **Manual Backup**: Run ./backup_stack.sh and verify the archive creation.
- <span style="font-size: 2em;">☐</span> **Integrity**: Validate the AES-256-CBC encryption of the backup archive.
- <span style="font-size: 2em;">☐</span> **Automation**: Confirm that monitor_backup.sh and discovery tasks are correctly set in crontab -e.

---
*This documentation is part of the Sovereign Stack project.
Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License (LICENSE).*
