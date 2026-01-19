# Restoration Guide: sovereign-stack

This guide explains how to restore your services from the encrypted archives created by `backup_stack.sh`. 



## 1. Prerequisites
* A fresh installation of the **sovereign-stack** (run `install.sh` first).
* Your encryption password (stored in `.env` as `BACKUP_PASSWORD`).
* **Backup Access:** Access to your backup target (Windows, Linux, or Mac) to retrieve the `.enc` archive.

---

## 2. Step-by-Step Recovery

### Step A: Decrypt the Archive
Move your backup file to the Pi and decrypt it:

    openssl enc -d -aes-256-cbc -pbkdf2 \
        -pass "pass:YOUR_PASSWORD_HERE" \
        -in sovereign_stack_DATE.tar.gz.enc \
        -out restored_stack.tar.gz

### Step B: Extract Configuration
Extract the files directly into your project directory:

    sudo tar -xzvf restored_stack.tar.gz -C /home/hvhoek/docker

### Step C: Restore Nextcloud Database
1.  **Start DB:** `docker compose up -d nextcloud-db`
2.  **Wait 10s** for initialization.
3.  **Import SQL:**
        cat /home/hvhoek/docker/nextcloud/nextcloud_db_export.sql | \
        docker exec -i nextcloud-db mariadb -u nextcloud -p"YOUR_DB_PASSWORD" nextcloud

### Step D: Restore Permissions
    sudo chown -R 33:33 /home/hvhoek/docker/nextcloud/data
    docker compose up -d

---

## 3. Special Case: Nextcloud Data
If `INCLUDE_NEXTCLOUD_DATA=true` was set, your files are in `nextcloud/data`. If they don't appear in the UI:

    docker exec --user www-data nextcloud-app php occ files:scan --all

---

## 4. Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Decryption Failed** | Verify `BACKUP_PASSWORD` and use `-pbkdf2`. |
| **Missing Videos** | Frigate videos are only included if `INCLUDE_FRIGATE_DATA=true`. |
