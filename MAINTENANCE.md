

# Maintenance Guide v1.0 - Staying Sovereign

This guide outlines the routine tasks required to keep your **sovereign-stack** healthy, fast, and secure on your Raspberry Pi 5.

## 1. Storage & Backup Hygiene
Your system is configured with a 7-day local retention policy.
- **Monitor Growth:** While the NVMe is large (1TB), Nextcloud data and Frigate recordings are the primary growth factors.
- **Check Disk Space:** Periodically verify that your SSD isn't reaching its limits.

## 2. Docker Maintenance
Over time, old Docker images (from updates) and stopped containers can consume significant space.
- **Image Pruning:** Remove unused layers and images that are no longer part of the stack.
- **Log Rotation:** Docker container logs can grow indefinitely if not managed.

## 3. System Updates
Digital sovereignty means controlling when and how you update.
- **OS Updates:** Keep the underlying Raspberry Pi OS secure.
- **Container Updates:** Update your stack using `docker compose pull`. Always check the changelogs of major services like Nextcloud before upgrading.

## 4. Automation: The Maintenance Script
To simplify these tasks, use the provided `clean_stack.sh` utility once a month.

## 5. Update Strategy: Informed Manual Control

To maintain stability and avoid "black box" automation, this stack follows an **Informed Manual** update policy.

### Guidelines:
1. **Verify Backups First**: Always check your morning email report (03:00/03:30) to ensure you have a fresh, verified backup before starting any system upgrade.
2. **Monthly Cycle**: Run the maintenance script (`clean_stack.sh`) monthly. If updates are pending, perform them manually when you have time to troubleshoot.
3. **The Upgrade Process**:
   - Run `sudo apt update` to refresh repositories.
   - Run `sudo apt upgrade` to install packages.
   - If a kernel update is installed, a system reboot is required.
4. **Container Hygiene**: Periodically pull new images for your stack to stay current with security patches for services like Nextcloud or Vaultwarden:
   ```bash
   cd ~/sovereign-stack
   docker compose pull
   docker compose up -d
   ```
---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
