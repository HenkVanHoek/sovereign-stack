# Part of the sovereign-stack project.
#
# Copyright (C) 2026 Henk van Hoek
# Licensed under the GNU General Public License v3.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# Restoration Guide: sovereign-stack (v4.0)

This guide explains how to restore your services from the encrypted archives created by `backup_stack.sh`. You can use the automated `restore_stack.sh` script or follow these manual steps.

## 1. Prerequisites
* A fresh installation of the **sovereign-stack** (run `INSTALL.sh` first).
* Your encryption password (stored in `.env` as `BACKUP_PASSWORD`).
* **Backup Access:** Retrieve the `.enc` archive from your remote target.
* **OpenSSL:** Ensure OpenSSL is installed on the Pi (v3.x requires PBKDF2 support).

---

## 2. Step-by-Step Recovery

### Step A: Decrypt the Archive
Move your backup file to the Pi (e.g., via SCP or SFTP) and decrypt it. Replace `FILENAME` with your actual file:

    openssl enc -d -aes-256-cbc -salt -pbkdf2 \
        -pass "pass:YOUR_BACKUP_PASSWORD" \
        -in FILENAME.tar.gz.enc \
        -out restored_stack.tar.gz

### Step B: Extract Configuration
Extract the files into your project directory. We use `/home/${USER}/docker` as the standard path:

    sudo tar -xzvf restored_stack.tar.gz -C /home/${USER}/docker

### Step C: Restore Nextcloud Database
1. **Start the Database Container:** `docker compose up -d nextcloud-db`
2. **Wait 15 seconds** for the database to initialize.
3. **Import the SQL Export:**
    
    docker exec -i nextcloud-db mariadb -u nextcloud -p"YOUR_DB_PASSWORD" nextcloud < /home/${USER}/docker/nextcloud/nextcloud_db_export.sql

### Step D: Surgical Permission Fix (Critical)
After extraction, file ownership may be reset to root. You MUST restore service-specific permissions:

    # 1. Reset general ownership to local user
    sudo chown -R $USER:$USER /home/${USER}/docker
    
    # 2. Nextcloud Data (www-data)
    sudo chown -R 33:33 /home/${USER}/docker/nextcloud/data
    
    # 3. Matrix / Conduit Database (conduit)
    # Check your container UID if different, usually 100 or root
    sudo chown -R 100:100 /home/${USER}/docker/matrix/db
    
    # 4. Bring the full stack online
    docker compose up -d

---

## 3. Verifying Backup Integrity

### Automated Check
The `monitor_backup.sh` script performs a nightly "dry-run" decryption to verify the archive stream and password without writing data to disk.

### Manual Integrity Test
To verify an archive without extracting it, check the tar header after decryption:

    openssl enc -d -aes-256-cbc -salt -pbkdf2 -pass "pass:PASSWORD" -in FILE.enc | tar -tzf -

---

## 4. Special Case: Nextcloud Data
If `INCLUDE_NEXTCLOUD_DATA="true"` was set, trigger a manual scan if files do not appear in the web interface:

    docker exec --user www-data nextcloud-app php occ files:scan --all

---

## 5. Troubleshooting

| Issue                 | Solution                                                           |
|:----------------------|:-------------------------------------------------------------------|
| **Decryption Failed** | Verify `BACKUP_PASSWORD`. V4.x scripts strictly require `-pbkdf2`. |
| **Bad Magic Number**  | The file is corrupted or was not encrypted with OpenSSL.           |
| **Permission Denied** | Use `sudo` for extraction and run the `chown` commands in Step D.  |
| **Database Error**    | Ensure the `nextcloud-db` container is running before importing.   |

---

## 6. Script Integrity (CRLF issues)
If you edited scripts on Windows, repair them using `sed` to remove hidden `^M` characters:

    sed -i 's/\r$//' /home/${USER}/docker/*.sh

---

*This documentation is part of the **Sovereign Stack** project. 
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. 
Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
