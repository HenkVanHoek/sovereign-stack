# Maintenance Guide v4.2.1 - Staying Sovereign

This guide outlines the routine tasks required to keep your **sovereign-stack** healthy, fast, and secure on your Raspberry Pi 5.

## 1. Inventory & Discovery Audit (v4.2.x)
With the introduction of the Infra Scanner, it is essential to verify your asset inventory monthly:
* **NetBox Consistency**: Ensure the virtual machines and containers listed in NetBox match your actual running services.
* **OctoPrint Status**: Verify that 3D printers are correctly identified and accessible via the scanner[cite: 3].
* **Credential Rotation**: Periodically review `credentials.json` for outdated SSH passwords.

## 2. Windows-based Development Workflow
Since the Sovereign Stack is developed in PyCharm on a Windows Host:
* **Version Control**: Always ensure `version.py` is the single source of truth for the project version.
* **Tag Synchronization**: After a release using `release.ps1`, verify that Git tags are pushed to GitHub (`git push --tags`) to keep all environments (HP/Lenovo) aligned.
* **PowerShell Integrity**: Ensure the Windows Execution Policy allows the execution of the local `release.ps1` script.

## 3. Storage & Backup Hygiene
Your system is configured with a 7-day local retention policy (defined by `BACKUP_RETENTION_DAYS` in `.env`).
* **Monitor Growth**: While the NVMe is large (1TB), Frigate recordings (NVR) and Nextcloud data are the primary growth factors.
* **Integrity Checks**: The `monitor_backup.sh` script verifies the AES-256-CBC encrypted archives daily.

## 4. Automation: The Maintenance Script
Use the provided `clean_stack.sh` utility once a month on the Raspberry Pi to simplify these tasks:
* **Docker Pruning**: Cleans up unused images and layers.
* **Permission Fixes**: Automatically enforces the surgical permission model (UID 33/100/999/70/1000).
* **Health Checks**: Verifies disk usage and available OS updates.

## 5. Update Strategy: Informed Manual Control
To maintain stability, this stack follows an **Informed Manual** update policy:
1. **Verify Backups**: Always check your morning email report (03:00/03:30) before starting any system upgrade.
2. **OS Updates**: Keep the Raspberry Pi OS secure via `sudo apt update && sudo apt upgrade`.
3. **Container Hygiene**: Periodically pull new images:
    ```bash
    cd ~/sovereign-stack
    docker compose pull
    docker compose up -d
    ```
4. **Permission Restore**: After updates, run `./clean_stack.sh` to restore surgical UID ownership.

---
*Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0.*
