# Maintenance Guide v4.2.0 - Staying Sovereign

This guide outlines the routine tasks required to keep your **sovereign-stack** healthy, fast, and secure on your Raspberry Pi 5.

## 1. Inventory & Discovery Audit (v4.2.0)
With the introduction of the Infra Scanner, it is essential to verify your asset inventory monthly:
* **NetBox Consistency**: Ensure the virtual machines and containers listed in NetBox match your actual running services. [cite: 3, 4]
* **OctoPrint Status**: Verify that 3D printers are correctly identified and accessible. [cite: 3, 4]
* **Credential Rotation**: Periodically review `credentials.json` for outdated SSH passwords. [cite: 1]

## 2. Windows-based Development Workflow
Since the Sovereign Stack is developed in PyCharm on a Windows Host:
* **Version Control**: Always ensure `version.py` is the single source of truth for the project version. [cite: 1]
* **Tag Synchronization**: After a release, verify that Git tags are pushed to GitHub (`git push --tags`) to keep the HP and Lenovo environments aligned. [cite: 1, 11]
* **PowerShell Integrity**: When using `release.ps1`, ensure the Execution Policy allows script execution. [cite: 1]

## 3. Storage & Backup Hygiene
Your system is configured with a 7-day local retention policy (defined by `BACKUP_RETENTION_DAYS` in `.env`). [cite: 11]
* **Disk Usage**: Monitor the 1TB NVMe SSD, specifically for Frigate recordings and Nextcloud data. [cite: 11]
* **Integrity Checks**: The `monitor_backup.sh` script verifies the AES-256-CBC encrypted archives daily.

## 4. Update Strategy: Informed Manual Control
To maintain stability, this stack follows an **Informed Manual** update policy:
1. **Verify Backups**: Check your morning email report (03:00/03:30) before starting any system upgrade. [cite: 11]
2. **OS Updates**: Keep the Raspberry Pi OS secure via `apt update && apt upgrade`. [cite: 11]
3. **Container Hygiene**: Periodically pull new images:
    ```bash
    cd ~/sovereign-stack
    docker compose pull
    docker compose up -d
    ```
4. **Permission Restore**: After updates, run `./clean_stack.sh` to restore surgical UID ownership (33/100/999/70/1000). [cite: 11]

---

*This documentation is part of the **Sovereign Stack** project.
Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
