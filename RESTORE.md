# Restoration Guide: Sovereign Stack (v4.5.0)

This guide explains how to restore your services from the encrypted archives created by `backup-stack.sh`. All backups are stored on the local 8TB USB drive as AES-256 encrypted snapshots.

## 1. Automated Restoration (Recommended)
The most reliable way to restore is using the `restore_stack.sh` script located in your project root. This script handles decryption, extraction, and automated SQL database imports.

```bash
cd ~/docker
./restore_stack.sh
```

---

## 2. Manual Recovery Steps
If you need to perform a manual recovery, follow these stages:

### Step A: Decrypt the Archive
Find your backup in the `/archives/` directory on your 8TB drive. Use OpenSSL to decrypt it:

```bash
openssl enc -d -aes-256-cbc -salt -pbkdf2 \
    -k "YOUR_BACKUP_ENCRYPTION_KEY" \
    -in /mnt/usb-8tb/backups/archives/sovereign_stack_DATE.tar.gz.enc \
    -out restored_stack.tar.gz
```

### Step B: Extract Files
Extract the decrypted archive into your project directory:

```bash
sudo tar -xzvf restored_stack.tar.gz -C ~/docker
```

### Step C: Restore Databases
Start the MariaDB container and import the SQL dump included in the archive:

```bash
docker compose up -d mariadb
sleep 15
docker exec -i mariadb mariadb -u root -p"NEXTCLOUD_DB_ROOT_PASSWORD" < ~/docker/all_databases.sql
```

### Step D: Correct Permissions (Critical)
After extraction, file ownership may be reset to root. You must restore local user ownership to ensure PyCharm and Docker can access the files:

```bash
# Reset ownership to the local user
sudo chown -R $USER:$USER ~/docker
```

---

## 3. Verifying Backup Integrity
You can verify an archive on the 8TB drive without extracting it by checking the tar header:

```bash
openssl enc -d -aes-256-cbc -salt -pbkdf2 -k "PASSWORD" -in FILE.enc | tar -tzf -
```

---

## 4. Troubleshooting

| Issue | Solution |
|:--- |:--- |
| **Decryption Failed** | Verify `BACKUP_ENCRYPTION_KEY` in `.env`. PBKDF2 is strictly required. |
| **Permission Denied** | Always use `sudo` for `tar` extraction and run the `chown` command afterward. |
| **Database Error** | Ensure the `mariadb` container is fully initialized before importing. |

---

*This documentation is part of the **Sovereign Stack** project.*
*Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0 License.*
