# First-Run Guide: Service Configuration & Trust

This guide covers the essential post-installation steps to ensure your **sovereign-stack** services are trusted, connected, and fully functional.

---

## 1. Step-CA: Root Certificate Trust Guide

Because sovereign-stack uses a private Certificate Authority (Step-CA), your devices will not recognize your local SSL certificates by default. You must install the Root Certificate on every device that accesses the stack.

### 1.1 Export the Root Certificate
First, you need to get the `root_ca.crt` file from your Raspberry Pi to your computer or phone. Run this on your Pi:

    cp ${DOCKER_ROOT}/step-ca/certs/root_ca.crt ~/root_ca.crt

Transfer this file to your device via SFTP, email, or a USB stick.

### 1.2 Installation per Device Type

#### Windows 10/11
1. Double-click the `root_ca.crt` file.
2. Click **Install Certificate...**
3. Select **Local Machine** and click Next.
4. Select **Place all certificates in the following store**.
5. Click **Browse** and select **Trusted Root Certification Authorities**.
6. Finish the wizard and restart your browser.

#### Android (13+)
1. Settings → Security & Privacy → More Security Settings.
2. Encryption & credentials → Install a certificate.
3. Select **CA certificate**.
4. Tap **Install anyway** (warning) and select your `root_ca.crt`.

#### iOS / iPhone
1. Send the file via AirDrop or Files app.
2. Open **Settings** → **Profile Downloaded** → **Install**.
3. **Crucial Step:** Go to Settings → General → About → **Certificate Trust Settings**.
4. Enable full trust for your Sovereign Root CA.

---

## 2. SMTP Alert Pipeline (msmtp)

To ensure you receive high-priority backup and health alerts, verify your SMTP connection via the `msmtp` client.

### 2.1 Test Connection
Run the following command on your Pi to send a test email:

    echo "Sovereign Stack: SMTP Test Successful" | msmtp your-email@provider.com

### 2.2 Troubleshooting
If the email does not arrive:
- Check the logs: `tail -f ${DOCKER_ROOT}/backups/cron.log`
- Verify your app-specific password in the `.env` file.

---

## 3. Nextcloud Talk: STUN/TURN Configuration

To enable video calls outside your local network, you must connect the Coturn service to Nextcloud.

1. Log in to your **Nextcloud** as an admin.
2. Go to **Administration Settings** → **Talk**.
3. Under **STUN servers**, add:
   - `yourdomain.com:3478`
4. Under **TURN servers**, add:
   - Server: `yourdomain.com:3478`
   - Secret: (Use the `COTUR_SECRET` from your `.env`)
   - Protocol: `UDP and TCP`

---

## 4. Backup Target: Wake-on-LAN Preparation

The backup pipeline includes `wake_target.sh` logic to ensure your remote workstation is online.

1. **BIOS/UEFI:** Ensure "Wake on LAN" or "Power on by PCI-E" is enabled on your backup PC.
2. **Windows Settings:** In Device Manager, find your Network Adapter → Properties → Power Management → Enable "Allow this device to wake the computer" and "Only allow a magic packet to wake the computer".
3. **MAC Address:** Verify that `BACKUP_TARGET_MAC` in your `.env` matches the address found in your router or via `ipconfig /all`.
4. **Path Notation:** For Windows targets, use the `/DRIVE:/path` format (e.g., `/H:/BackupsPi`) to ensure compatibility with SFTP and the monitor script.

---

## 5. Summary of Automated Tasks
- **Backups:** Run daily at `03:00` via `backup_stack.sh`.
- **Dead Man's Switch:** Verifies integrity and remote arrival at `12:00` (Noon) via `monitor_backup.sh`.
- **Container Updates:** Watchtower checks for security patches every 24 hours.

---

## 6. Homarr Dashboard Setup

After starting the stack, your Homarr dashboard will be empty. Follow these steps to populate it:

1. **Access the Dashboard:** Go to `http://<your-pi-ip>:7575` or your domain.
2. **Enter Edit Mode:** Click the pencil icon in the top right corner.
3. **Docker Integration:** Enable "Docker Integration" on your tiles to automatically see CPU and RAM usage for your containers.
4. **Health Pings:** For internal health checks, use the service names defined in `docker-compose.yaml` (e.g., `http://adguardhome`).

---

## 7. Verifying the Sovereign Guards

To ensure your stack is correctly protected, you can perform a manual "Pre-flight" check:

1. **Environment Test:** Run `./verify_env.sh` manually. It should exit silently if everything is correct.
2. **Identity Guard:** Attempt to run `./backup_stack.sh` with `sudo`. The script should immediately block the execution and exit with an error.
3. **Anti-Stacking:** Open two terminals and attempt to run `./monitor_backup.sh` simultaneously. The second instance should exit immediately thanks to the `flock` protection.

---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
