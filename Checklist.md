# Deployment Verification Checklist

Before going live with the full stack, perform these checks to ensure autonomy and resilience.

## 1. Environment & Connectivity Checks
- [ ] **Secrets:** Verify `.env` exists and contains no `<REPLACE_WITH...>` placeholders.
- [ ] **Permissions:** Run `chmod +x ./*.sh` and verify scripts are executable.
- [ ] **Remote Link:** Run `./test_remote_connection.sh` to confirm WoL and SSH access.
- [ ] **Internal Trust:** Run `./gen_cert.sh` for at least one subdomain to verify Step-CA is operational.

## 2. Service Orchestration
- [ ] **Netbox Init:** Verify that the Netbox media, reports, and scripts directories exist and have UID 1000 ownership (`sudo chown -R 1000:1000 ${DOCKER_ROOT}/netbox/`).
- [ ] **Stack Boot:** Run `docker compose up -d` and check for any "Exit 1" containers.
- [ ] **Log Audit:** Check `docker logs fail2ban` to ensure security jails are active.
- [ ] **Nextcloud Data:** Run `./fix-nextcloud-perms.sh` to prevent access errors.

## 3. Communication & Alerting
- [ ] **SMTP Pipe:** Send a test email via `msmtp` to verify your Freedom.nl relay.
- [ ] **Dashboard:** Verify all 19+ services appear correctly in the Homarr dashboard.

## 4. Disaster Recovery Preparation
- [ ] **Backup Test:** Trigger a manual backup: `./backup_stack.sh`.
- [ ] **Integrity:** Verify the local archive with `openssl enc -d ... | tar -tzf -`.
- [ ] **Cron Verification:** Run `crontab -l` to ensure the 03:00 and 04:30 slots are filled.

---
*Status: Ready for Deployment*
---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
