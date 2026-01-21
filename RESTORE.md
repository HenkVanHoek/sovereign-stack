# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# sovereign-stack Selective Backup Pipeline 

# Restoration Guide: sovereign-stack [cite: 2025-06-11]

This guide explains how to restore your services from the encrypted archives created by `backup_stack.sh`. 

## 1. Prerequisites
* A fresh installation of the **sovereign-stack** (run `install.sh` first).
* Your encryption password (stored in `.env` as `BACKUP_PASSWORD`).
* **Backup Access:** Access to your backup target (Windows, Linux, or Mac) to retrieve the `.enc` archive.
* **OpenSSL:** Ensure OpenSSL is installed on the Pi (standard on Raspberry Pi OS).

---

## 2. Step-by-Step Recovery

### Step A: Decrypt the Archive
Move your backup file to the Pi (e.g., via SCP or SFTP) and decrypt it. Replace `DATE` with your actual filename:

    openssl enc -d -aes-256-cbc -salt -pbkdf2 \
        -pass "pass:YOUR_BACKUP_PASSWORD" \
        -in sovereign_stack_DATE.tar.gz.enc \
        -out restored_stack.tar.gz

### Step B: Extract Configuration
Extract the files directly into your project directory. We use `sudo` to ensure that files created by Docker can be overwritten:

    sudo tar -xzvf restored_stack.tar.gz -C /${USER}/docker

### Step C: Restore Nextcloud Database
1. **Start the Database Container:** docker compose up -d nextcloud-db
2. **Wait 10-15 seconds** for the database to initialize.
3. **Import the SQL Export:**
    
    cat /${USER}/docker/nextcloud/nextcloud_db_export.sql | \
    docker exec -i nextcloud-db mariadb -u nextcloud -p"YOUR_DB_PASSWORD" nextcloud

### Step D: Restore Permissions & Start Stack
After extraction, ownership might be mixed. Reset ownership to your local user for the configuration, but keep the data directory for Nextcloud assigned to the webserver user (UID 33):

    # Reset general ownership
    sudo chown -R $USER:$USER /${USER}/docker
    
    # Specific fix for Nextcloud Data
    sudo chown -R 33:33 /${USER}/docker/nextcloud/data
    
    # Bring the full stack online
    docker compose up -d

---

## 3. Verifying Backup Integrity (The Restore Check)
To avoid "Schrödinger's Backup", the stack includes automated and manual integrity checks.

### Automated Check
The `monitor_backup.sh` script automatically performs a "dry-run" decryption every night. It decrypts the latest local archive in-memory and verifies the internal structure without writing unencrypted data to the disk.

### Manual Check
If you want to manually verify an archive before attempting a full restore, run the following command (replace PASSWORD and FILE):

    openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:PASSWORD" -in FILE.enc | tar -tzf -

---

## 4. Special Case: Nextcloud Data
If `INCLUDE_NEXTCLOUD_DATA="true"` was set, your files are restored to `nextcloud/data`. If the files do not appear immediately in the Nextcloud web interface, trigger a manual scan:

    docker exec --user www-data nextcloud-app php occ files:scan --all

---

## 5. Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Decryption Failed** | Verify `BACKUP_PASSWORD`. Ensure you are using `-pbkdf2` as used in v3.x scripts. |
| **Bad Magic Number** | This usually means the file is corrupted or not a valid OpenSSL encrypted file. |
| **Permission Denied** | Ensure you used `sudo` during the `tar` extraction (Step B). |
| **Missing Videos** | Frigate videos are only included if `INCLUDE_FRIGATE_DATA="true"` was set in `.env`. |
| **Database Connection Error** | Verify that the password in `.env` matches the password used during the SQL import. |

---

## 6. Script Integrity (CRLF issues)
If you edited the restore commands or scripts on a Windows machine, you might encounter execution errors due to hidden carriage return characters (`^M`) [cite: 2026-01-21]. Use `vi` to check for hidden characters or run the following to repair the files on the Pi [cite: 2025-11-16]:

    sed -i 's/\r$//' restore_stack.sh
    sed -i 's/\r$//' monitor_backup.sh
    sed -i 's/\r$//' backup_stack.sh
