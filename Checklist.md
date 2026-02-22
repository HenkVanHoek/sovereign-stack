# Deployment Verification Checklist (v4.2.0)

Voer deze controles uit voordat de stack live gaat om autonomie en veerkracht te garanderen.

## 1. Environment & Connectivity Checks
- [ ] **Versioning**: Controleer of `version.py` op "4.2.0" staat.
- [ ] **Secrets**: Controleer of `.env` bestaat en geen `<REPLACE_WITH...>` placeholders bevat.
- [ ] **Consistency**: Voer `./check_env_consistency.sh` uit om de 56 variabelen te valideren.
- [ ] **Permissions**: Voer `chmod +x ./*.sh` uit en controleer of alle scripts uitvoerbaar zijn.
- [ ] **Remote Link**: Voer `./test_remote_connection.sh` uit (WoL en SSH-toegang naar targets).
- [ ] **Internal Trust**: Genereer minimaal één certificaat via `./gen_cert.sh` om Step-CA te testen.

## 2. Infrastructure Discovery (v4.2.0)
- [ ] **Inventory Split**: Controleer of `inventory.json` (metadata) en `credentials.json` (secrets) aanwezig zijn.
- [ ] **NetBox Init**: Voer `seed_netbox.py` uit om de standaard Sovereign Stack types aan te maken.
- [ ] **Scanner Build**: Controleer of de `infra-scanner` container succesvol bouwt met `uv`.
- [ ] **First Scan**: Voer een handmatige scan uit en controleer of Docker containers en VM's in NetBox verschijnen.
- [ ] **OctoPrint**: Controleer of actieve OctoPrint instances worden gedetecteerd door de scanner.

## 3. Service Orchestration
- [ ] **Netbox Permissions**: Controleer of de media/reports mappen eigendom zijn van UID 1000.
- [ ] **Stack Boot**: Voer `docker compose up -d` uit en check op "Exit 1" containers.
- [ ] **Log Audit**: Controleer `docker logs fail2ban` om te zien of de jails actief zijn.
- [ ] **Nextcloud Data**: Voer `./fix-nextcloud-perms.sh` uit om toegangsrechten te herstellen.

## 4. Communication & Alerting
- [ ] **SMTP Pipe**: Test de mailverbinding via `msmtp` naar je Freedom.nl relay.
- [ ] **Dashboard**: Controleer of alle services (inclusief NetBox en de Scanner status) correct in Homarr staan.
- [ ] **Monitoring**: Controleer of de `monitor_backup.sh` correct in de crontab staat.

## 5. Disaster Recovery Preparation
- [ ] **Backup Test**: Voer een handmatige backup uit: `./backup_stack.sh`.
- [ ] **Integrity**: Valideer het lokale archief: `openssl enc -d ... | tar -tzf -`.
- [ ] **Cron Slots**: Controleer via `crontab -l` of de 03:00 en 04:30 slots gevuld zijn.

---

*Dit document is onderdeel van het Sovereign Stack project.*
