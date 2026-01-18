# Recovery Guide: sovereign-stack

    In the event of hardware failure or data corruption, follow these 
    steps to restore your infrastructure from an encrypted backup.

    ## 1. Prepare the Environment
    On a fresh Raspberry Pi OS installation:
    1. Clone the repository: `git clone <your-repo-url> ~/docker`
    2. Run the installer: `chmod +x install.sh && ./install.sh`
       *(Ensure you use the same BACKUP_PASSWORD as your previous setup)*.

    ## 2. Locate your Backup
    Ensure your latest `.enc` file is present in `${DOCKER_ROOT}/backups/`. 
    If it's only on your Windows PC, SFTP it back to the Pi:
    `sftp <user>@<pc-ip>:[path/to/backup] ${DOCKER_ROOT}/backups/`

    ## 3. Run the Restore Utility
    The restore script automates decryption, file extraction, and 
    database injection:

    ```bash
    chmod +x restore_stack.sh
    ./restore_stack.sh
    ```

    ## 4. Manual Verification
    Once the script finishes:
    1. **Containers:** Start the full stack: `docker compose up -d`.
    2. **SSL:** Check if Nginx Proxy Manager recognizes your certs.
    3. **Nextcloud:** Verify that your files and users are visible.
    4. **MQTT:** Re-create MQTT users if they were not part of the 
       persisted volume (see INSTALL.md).

    ## 5. Troubleshooting the Restore
    - **Decryption Error:** Verify `BACKUP_PASSWORD` in `.env`.
    - **Database Error:** Ensure the `nextcloud-db` container is 
      running before the script attempts the MariaDB import.
