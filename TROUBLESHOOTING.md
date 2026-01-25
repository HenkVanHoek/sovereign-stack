# Troubleshooting sovereign-stack

## 1. Browser remembers old certificate (HSTS)
If you recently changed your SSL certificate (e.g., from Let's Encrypt to Smallstep) and the browser shows a security warning, you must clear the HSTS cache.

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
`Proxy Hosts` -> `Edit` -> `SSL` -> `SSL Certificate`.

---

## 3. External IP detected via VPN (Wireguard)
When using Wireguard, NPM may see your public WAN IP instead of your internal VPN IP.

### Diagnosis
Check which client IP is being blocked by searching for 403 errors in the logs:

    docker exec -it npm cat /data/logs/proxy-host-X_access.log | grep 403

### Solution
Add your public static IPv4 address to the **NPM Access List**. This ensures access is granted even when traffic is masqueraded through the public gateway.

---

## 4. Permission Denied on Step-CA
If `step-ca` fails to start with a 'Permission denied' error, the host directory requires UID 1000 ownership.

**Fix:**

    sudo chown -R 1000:1000 ${DOCKER_ROOT}/step-ca

---

## 5. Browser Caching & Service Workers
Modern browsers use Service Workers that can persist even after a restart, causing 'Fetch Errors' after environment changes.

### Recovery Steps:
1. Fully log out of the service (e.g., Vaultwarden/Nextcloud).
2. Open Developer Tools (`F12`) -> **Application** -> **Clear Storage** -> **Clear Site Data**.
3. Perform a hard refresh (`Ctrl + F5`).

---

## 6. Firewall: Subnet Mask Precision
When configuring **UFW** to allow traffic from Docker to host-mode services (like Home Assistant), use the `/12` mask.

**Command:**

    sudo ufw allow from 172.16.0.0/12 to any

---

## 7. Prosody: "No channel binding" in Conversations (Android)
Android clients might fail to connect behind NPM because of TLS termination conflicts with SASL channel binding.

### Solution
Disable the "PLUS" SASL mechanisms in `prosody.cfg.lua`:

    vi ${DOCKER_ROOT}/prosody/config/prosody.cfg.lua

Add/Update:

    sasl_forbidden_mechanisms = { "SCRAM-SHA-1-PLUS", "SCRAM-SHA-256-PLUS" }

Restart: 

    docker compose restart prosody

---

## 8. Scripts/Docker fail due to Windows Line Endings (^M)
Carriage Return (`\r`) characters from Windows editors cause syntax errors in Bash. While the stack's loader attempts to strip these, manual edits can still introduce them.

### Diagnosis
Check for `^M` at the end of lines: 

    cat -v .env

### Solution
Strip carriage returns: 

    sed -i 's/\r$//' ${DOCKER_ROOT}/.env*

---

## 9. Backup Verification Fails on Windows Target
If the `monitor_backup.sh` script reports that `'test' is not recognized as a command`.

### Cause
The script is attempting to use Linux commands on a Windows machine.

### Fix
Ensure the `BACKUP_TARGET_OS="windows"` variable is correctly set in your `.env` file. This tells the monitor to use `if exist` instead of `test`.

---

## 10. Remote Path Not Found (Leading Slash Issue)
If the monitor script reports `ERROR: Remote file not found` even though the file exists on your Windows target.

### Cause
SSH on Windows interprets paths differently than SFTP. A path like `/H:/Backups` works for SFTP but fails for Windows CMD commands via SSH.

### Fix
The stack now automatically strips the leading slash for Windows targets. Ensure your `.env` path is formatted as `/H:/YourPath` and that you are using `monitor_backup.sh` v3.6.3 or higher.

---

## 11. Backup: "Bad Decrypt" / Password Errors
If `restore_stack.sh` or `monitor_backup.sh` fails with "Bad Decrypt" but the password is correct.

### Cause
The stack uses **PBKDF2** for key derivation. Commands missing the `-pbkdf2` flag will fail to decrypt v3.x archives.

### Fix
Ensure all manual OpenSSL commands include the `-pbkdf2` flag:

    openssl enc -d -aes-256-cbc -salt -pbkdf2 ...

---

## 12. Database: MariaDB Injection Fails
When running `restore_stack.sh`, the SQL import might fail with "Connection Refused".

### Cause
The MariaDB container is either not running or hasn't finished its internal initialization.

### Fix
1. Start the DB: 

    docker compose up -d nextcloud-db

2. Wait **15-20 seconds** for the schemas to initialize before re-running the restore.

---

## 13. Identity Guard Error
If you see the error `[ERROR] This script should NOT be run with sudo or as root`.

### Cause
Running backup or utility scripts with `sudo` prevents the script from accessing your user-specific SSH keys and identities.

### Fix
Always run the stack's scripts as a standard user (e.g., `hvhoek`). The scripts are designed to handle permissions internally.

---

## 14. Nextcloud: "Internal Server Error" after Restore
Usually caused by incorrect ownership of the `data` directory.

### Fix
Run the specialized permission utility:

    ./fix-nextcloud-perms.sh

---

## 15. Wake-on-LAN: Missing Dependency
If `wake_target.sh` reports that it cannot find the `wakeonlan` command.

### Fix
Install the utility manually:

    sudo apt update && sudo apt install wakeonlan -y
