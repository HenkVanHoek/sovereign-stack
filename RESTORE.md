# Recovery Guide: sovereign-stack

Follow these steps to restore your infrastructure from an encrypted backup.



## 1. Prepare the Environment
On a fresh Raspberry Pi OS installation:
1. Clone the repository: `git clone <your-repo-url> ~/docker`
2. Run the installer: `./install.sh`
   *(Ensure you use the same BACKUP_PASSWORD as your previous setup)*.

## 2. Locate your Backup
Ensure your latest `.enc` file is present in `${DOCKER_ROOT}/backups/`. If it is only on your workstation, SFTP it back to the Pi:

    sftp <user>@<pc-ip>:[path/to/backup] ${DOCKER_ROOT}/backups/

## 3. Run the Restore Utility
The restore script automates decryption, file extraction, and database injection:

    chmod +x restore_stack.sh
    ./restore_stack.sh

## 4. Manual Verification
1. **Launch:** `docker compose up -d`.
2. **SSL:** Confirm Nginx Proxy Manager recognizes your certs.
3. **Database:** Verify Nextcloud data is intact.

## 5. Troubleshooting
- **Decryption:** Verify `BACKUP_PASSWORD` in `.env`.
- **Database:** Ensure `nextcloud-db` is running before starting the restore script.
