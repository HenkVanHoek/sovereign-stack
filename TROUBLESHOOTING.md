# Troubleshooting sovereign-stack [cite: 2026-01-22]

## 1. Browser remembers old certificate (HSTS)
If you recently changed your SSL certificate (e.g., from Let's Encrypt to Smallstep) and the browser shows a security warning, you must clear the HSTS cache. [cite: 2026-01-22]

### Chrome / Edge / Brave
1. Navigate to `chrome://net-internals/#hsts`
2. Under **"Delete domain security policies"**, enter your domain: `home.piselfhosting.com`
3. Click **"Delete"**.

### Firefox
1. Open History (`Ctrl + Shift + H`).
2. Right-click on the domain and select **"Forget About This Site"**.

---

## 2. NPM Certificate Mismatch
If the browser shows an "Invalid Certificate" error, ensure that the correct certificate is selected in the Nginx Proxy Manager UI:
`Proxy Hosts` -> `Edit` -> `SSL` -> `SSL Certificate`. [cite: 2026-01-22]

---

## 3. External IP detected via VPN (Wireguard)
When using Wireguard, NPM may see your public WAN IP instead of your internal VPN IP. [cite: 2026-01-22]

### Diagnosis
Check which client IP is being blocked by searching for 403 errors in the logs:

    docker exec -it npm cat /data/logs/proxy-host-X_access.log | grep 403

### Solution
Add your public static IPv4 address to the **NPM Access List**. This ensures access is granted even when traffic is masqueraded through the public gateway. [cite: 2026-01-22]

---

## 4. Permission Denied on Step-CA
If `step-ca` fails to start with a 'Permission denied' error, the host directory requires UID 1000 ownership. [cite: 2026-01-22]

**Fix:**

    sudo chown -R 1000:1000 ${DOCKER_ROOT}/step-ca

---

## 5. Browser Caching & Service Workers
Modern browsers use Service Workers that can persist even after a restart, causing 'Fetch Errors' after environment changes. [cite: 2026-01-22]

### Recovery Steps:
1. Fully log out of the service (e.g., Vaultwarden/Nextcloud).
2. Open Developer Tools (`F12`) -> **Application** -> **Clear Storage** -> **Clear Site Data**.
3. Perform a hard refresh (`Ctrl + F5`). [cite: 2026-01-22]

---

## 6. Firewall: Subnet Mask Precision
When configuring **UFW** to allow traffic from Docker to host-mode services (like Home Assistant), use the `/12` mask. [cite: 2026-01-22]

**Command:**

    sudo ufw allow from 172.16.0.0/12 to any

---

## 7. Prosody: "No channel binding" in Conversations (Android)
Android clients might fail to connect behind NPM because of TLS termination conflicts with SASL channel binding. [cite: 2026-01-22]

### Solution
Disable the "PLUS" SASL mechanisms in `prosody.cfg.lua`: [cite: 2026-01-22]

    vi ${DOCKER_ROOT}/prosody/config/prosody.cfg.lua

Add/Update:

    sasl_forbidden_mechanisms = { "SCRAM-SHA-1-PLUS", "SCRAM-SHA-256-PLUS" }

Restart: `docker compose restart prosody`. [cite: 2026-01-22]

---

## 8. Scripts/Docker fail due to Windows Line Endings (^M)
Carriage Return (`\r`) characters from Windows editors cause syntax errors in Bash. [cite: 2026-01-21, 2026-01-22]

### Diagnosis
Check for `^M` at the end of lines: `cat -v .env`. [cite: 2026-01-22]

### Solution
Strip carriage returns: `sed -i 's/\r$//' ${DOCKER_ROOT}/.env*`. [cite: 2026-01-22]

---

## 9. Backup: "Bad Decrypt" / Password Errors
If `restore_stack.sh` or `monitor_backup.sh` fails with "Bad Decrypt" but the password is correct. [cite: 2026-01-22]

### Cause
As of v3.x, the stack uses **PBKDF2** for key derivation. Older backups or manual commands missing the `-pbkdf2` flag will fail. [cite: 2026-01-22]

### Fix
Ensure all manual OpenSSL commands include the `-pbkdf2` flag: [cite: 2026-01-22]

    openssl enc -d -aes-256-cbc -salt -pbkdf2 ...

---

## 10. Database: MariaDB Injection Fails
When running `restore_stack.sh`, the SQL import might fail with "Connection Refused". [cite: 2026-01-22]

### Cause
The MariaDB container is either not running or the database has not finished initializing its internal schemas. [cite: 2026-01-22]

### Fix
1. Start the DB: `docker compose up -d nextcloud-db`. [cite: 2026-01-22]
2. Wait exactly **15-20 seconds** before re-running the restore script. [cite: 2026-01-22]

---

## 11. Nextcloud: "Internal Server Error" after Restore
Usually caused by incorrect ownership of the `data` directory after moving files between filesystems. [cite: 2026-01-22]

### Fix
Run the specialized permission utility: [cite: 2026-01-22]

    ./fix-nextcloud-perms.sh
