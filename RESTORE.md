# Restoration Guide: sovereign-stack

This guide explains how to restore your services from the encrypted archives created by `backup_stack.sh`. 



## 1. Prerequisites
* A fresh installation of the **sovereign-stack** (run `install.sh` first).
* Your encryption password (stored in `.env` as `BACKUP_PASSWORD`).
* The encrypted backup file (e.g., `sovereign_stack_20260119_030000.tar.gz.enc`).

---

## 2. Step-by-Step Recovery

### Step A: Decrypt the Archive
Move your backup file to the Pi and decrypt it using OpenSSL.

    openssl enc -d -aes-256-cbc -pbkdf2 \
        -pass "pass:YOUR_PASSWORD_HERE" \
        -in sovereign_stack_DATE.tar.gz.enc \
        -out restored_stack.tar.gz

### Step B: Extract the Configuration and Data
Extract the files directly into your project directory. This will overwrite existing configurations with your backed-up versions.

    sudo tar -xzvf restored_stack.tar.gz -C /home/hvhoek/docker

### Step C: Restore the Nextcloud Database
Because we use a **Selective Backup**, the raw database folder was excluded. We must now import the SQL dump into a fresh MariaDB container.

1.  **Start the database container:**
        docker compose up -d nextcloud-db

2.  **Wait 10 seconds** for the database to initialize.

3.  **Import the SQL dump:**
        cat /home/hvhoek/docker/nextcloud/nextcloud_db_export.sql | \
        docker exec -i nextcloud-db mariadb -u nextcloud -p"YOUR_DB_PASSWORD" nextcloud

### Step D: Restore Permissions and Launch
Nextcloud is sensitive to file permissions. Ensure the data directory is owned by the webserver user inside the container.

    sudo chown -R 33:33 /home/hvhoek/docker/nextcloud/data
    docker compose up -d

---

## 3. Special Case: Recovering Nextcloud Data
If you set `INCLUDE_NEXTCLOUD_DATA=true`, your photos and documents are inside the archive. After Step B, they will be located in `/home/hvhoek/docker/nextcloud/data`.

If the files do not appear in the Nextcloud UI immediately, run a manual scan:

    docker exec --user www-data nextcloud-app php occ files:scan --all

---

## 4. Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Decryption Failed** | Verify your `BACKUP_PASSWORD`. Ensure you are using the same OpenSSL version/parameters (`-pbkdf2`). |
| **DB Connection Error** | Ensure the `nextcloud-db` container is running before attempting the SQL import. |
| **Missing Videos** | Remember: If `INCLUDE_FRIGATE_DATA=false` was set, the `storage/` folder will be empty. |

---

### Final Note on Sovereignty
Regularly test this restoration process on a secondary Pi or a virtual machine. **A backup is not a backup until a restore has been verified.**
