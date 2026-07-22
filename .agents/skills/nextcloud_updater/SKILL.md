---
name: nextcloud-updater
description: Instructions, routines, and troubleshooting guidelines for managing automated and manual Nextcloud component and app updates on the Sovereign Stack. Activate this skill when performing Nextcloud maintenance, app updates, or resolving Nextcloud 502 Bad Gateway errors related to component upgrades.
---

# Nextcloud Updater Skill

This skill provides the knowledge and procedures to safely update and troubleshoot Nextcloud components and apps on the Sovereign Stack.

## 1. Automated Nightly Updates

Nextcloud apps are automatically updated nightly at **04:30 AM** via the crontab executing:
`/home/REPLACE_WITH_USER/sovereign-stack/update_nextcloud_apps.sh`

Logs for the nightly run are written to:
`/home/REPLACE_WITH_USER/sovereign-stack/logs/nextcloud_update.log`

### What the script does:
1. Verifies that the `nextcloud-app` container is running.
2. Runs `occ app:update --all` to update all apps.
3. Runs `occ upgrade` to apply pending database migrations.
4. Runs `occ db:add-missing-indices` to optimize app database tables.
5. Restarts the `nextcloud-app` container (`docker restart nextcloud-app`) to flush the PHP OPCache and reload classes cleanly.

---

## 2. Troubleshooting Update Failures

### 2.1 502 Bad Gateway after Updates
If the Nextcloud web UI displays a `502 Bad Gateway` error immediately after updates:
- **Cause**: PHP OPCache holds stale references to pre-compiled files in memory, which crashes the PHP engine with a `Segmentation Fault (11)`.
- **Solution**: Restart the `nextcloud-app` container to clear the cache:
  ```bash
  docker restart nextcloud-app
  ```

### 2.2 App Incompatibility / Crash on Boot
If Nextcloud fails to boot because of a newly updated app (e.g., `TypeError` or missing tables in `nextcloud.log`):
1. Locate the Nextcloud application log on the host:
   `${DOCKER_ROOT}/nextcloud/data/data/nextcloud.log`
2. Identify which app is throwing the error (e.g., `drawio` throwing a constructor `TypeError`).
3. Disable the failing app from the command line:
   ```bash
   docker exec -u www-data nextcloud-app php occ app:disable <app_name>
   ```
4. Restart the nextcloud-app container to clear memory:
   ```bash
   docker restart nextcloud-app
   ```

### 2.3 Maintenance Mode Conflicts
- Never manually enable Nextcloud maintenance mode (`occ maintenance:mode --on`) *before* running `occ upgrade` or `occ db:add-missing-indices`. Nextcloud's upgrade and database commands expect maintenance mode to be OFF at startup (they will toggle it themselves if needed). Running them while maintenance mode is manually enabled will trigger errors.

---

## 3. Reference Files
- Main script: [update_nextcloud_apps.sh](file:///home/hvhoek/PycharmProjects/sovereign-stack/update_nextcloud_apps.sh)
- Logs: [nextcloud_update.log](file:///home/hvhoek/PycharmProjects/sovereign-stack/logs/nextcloud_update.log)
- Documentation: [MAINTENANCE.md](file:///home/hvhoek/PycharmProjects/sovereign-stack/MAINTENANCE.md)
