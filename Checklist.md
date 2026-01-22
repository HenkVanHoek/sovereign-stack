# Deployment Verification Checklist [cite: 2026-01-22]

Before going live with the full stack, perform these checks to ensure autonomy and resilience. [cite: 2026-01-22]

## 1. Environment & Connectivity Checks
- [ ] **Secrets:** Verify `.env` exists and contains no `<REPLACE_WITH...>` placeholders. [cite: 2026-01-22]
- [ ] **Permissions:** Run `chmod +x ./*.sh` and verify scripts are executable. [cite: 2026-01-22]
- [ ] **Remote Link:** Run `./test_remote_connection.sh` to confirm WoL and SSH access. [cite: 2026-01-22]
- [ ] **Internal Trust:** Run `./gen_cert.sh` for at least one subdomain to verify Step-CA is operational. [cite: 2026-01-22]

## 2. Service Orchestration
- [ ] **Stack Boot:** Run `docker compose up -d` and check for any "Exit 1" containers. [cite: 2026-01-22]
- [ ] **Log Audit:** Check `docker logs fail2ban` to ensure security jails are active. [cite: 2026-01-22]
- [ ] **Nextcloud Data:** Run `./fix-nextcloud-perms.sh` to prevent access errors. [cite: 2026-01-22]

## 3. Communication & Alerting
- [ ] **SMTP Pipe:** Send a test email via `msmtp` to verify your Freedom.nl relay. [cite: 2026-01-22]
- [ ] **Dashboard:** Verify all 19+ services appear correctly in the Homarr dashboard. [cite: 2026-01-22]

## 4. Disaster Recovery Preparation
- [ ] **Backup Test:** Trigger a manual backup: `./backup_stack.sh`. [cite: 2026-01-22]
- [ ] **Integrity:** Verify the local archive with `openssl enc -d ... | tar -tzf -`. [cite: 2026-01-22]
- [ ] **Cron Verification:** Run `crontab -l` to ensure the 03:00 and 04:30 slots are filled. [cite: 2026-01-22]

---
*Status: Ready for Deployment* [cite: 2026-01-22]
