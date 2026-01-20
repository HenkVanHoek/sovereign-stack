# Restoration Guide: sovereign-stack

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

    sudo tar -xzvf restored_stack.tar.gz -C /home/hvhoek/docker

### Step C: Restore Nextcloud Database
1.  **Start the Database Container:** docker compose up -d nextcloud-db

2.  **Wait 10-15 seconds** for the database to initialize.
3.  **Import the SQL Export:**
    
        cat /home/hvhoek/docker/nextcloud/nextcloud_db_export.sql | \
        docker exec -i nextcloud-db mariadb -u nextcloud -p"YOUR_DB_PASSWORD" nextcloud

### Step D: Restore Permissions & Start Stack
After extraction, ownership might be mixed. Reset ownership to your local user for the configuration, but keep the data directory for Nextcloud assigned to the webserver user (UID 33):

    # Reset general ownership
    sudo chown -R $USER:$USER /home/hvhoek/docker
    
    # Specific fix for Nextcloud Data
    sudo chown -R 33:33 /home/hvhoek/docker/nextcloud/data
    
    # Bring the full stack online
    docker compose up -d

---

## 3. Special Case: Nextcloud Data
If `INCLUDE_NEXTCLOUD_DATA="true"` was set, your files are restored to `nextcloud/data`. If the files do not appear immediately in the Nextcloud web interface, trigger a manual scan:

    docker exec --user www-data nextcloud-app php occ files:scan --all

---

## 4. Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Decryption Failed** | Verify `BACKUP_PASSWORD`. Ensure you are using `-pbkdf2` as used in v3.x scripts. |
| **Bad Magic Number** | This usually means the file is corrupted or not a valid OpenSSL encrypted file. |
| **Permission Denied** | Ensure you used `sudo` during the `tar` extraction (Step B). |
| **Missing Videos** | Frigate videos are only included if `INCLUDE_FRIGATE_DATA="true"` was set in `.env`. |
| **Database Connection Error** | Verify that the password in `.env` matches the password used during the SQL import. |

---

## 5. Script Integrity (CRLF issues)
If you edited the restore commands or scripts on a Windows machine, you might encounter execution errors. Use `vi` to check for hidden characters or run:

    sed -i 's/\r$//' restore_stack.sh