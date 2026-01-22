# First-Run Guide: Service Configuration & Trust [cite: 2026-01-22]

This guide covers the essential post-installation steps to ensure your **sovereign-stack** services are trusted, connected, and fully functional. [cite: 2026-01-22]

---

## 1. Step-CA: Root Certificate Trust Guide [cite: 2026-01-22]

Because sovereign-stack uses a private Certificate Authority (Step-CA), your devices will not recognize your local SSL certificates by default. You must install the Root Certificate on every device that accesses the stack. [cite: 2026-01-22]

### 1.1 Export the Root Certificate [cite: 2026-01-22]
First, you need to get the `root_ca.crt` file from your Raspberry Pi to your computer or phone. Run this on your Pi: [cite: 2026-01-22]

    cp ${DOCKER_ROOT}/step-ca/certs/root_ca.crt ~/root_ca.crt

Transfer this file to your device via SFTP, email, or a USB stick. [cite: 2026-01-22]

### 1.2 Installation per Device Type [cite: 2026-01-22]

#### Windows 10/11 [cite: 2026-01-22]
1. Double-click the `root_ca.crt` file. [cite: 2026-01-22]
2. Click **Install Certificate...** [cite: 2026-01-22]
3. Select **Local Machine** and click Next. [cite: 2026-01-22]
4. Select **Place all certificates in the following store**. [cite: 2026-01-22]
5. Click **Browse** and select **Trusted Root Certification Authorities**. [cite: 2026-01-22]
6. Finish the wizard and restart your browser. [cite: 2026-01-22]

#### Android (13+) [cite: 2026-01-22]
1. Settings → Security & Privacy → More Security Settings. [cite: 2026-01-22]
2. Encryption & credentials → Install a certificate. [cite: 2026-01-22]
3. Select **CA certificate**. [cite: 2026-01-22]
4. Tap **Install anyway** (warning) and select your `root_ca.crt`. [cite: 2026-01-22]

#### iOS / iPhone [cite: 2026-01-22]
1. Send the file via AirDrop or Files app. [cite: 2026-01-22]
2. Open **Settings** → **Profile Downloaded** → **Install**. [cite: 2026-01-22]
3. **Crucial Step:** Go to Settings → General → About → **Certificate Trust Settings**. [cite: 2026-01-22]
4. Enable full trust for your Sovereign Root CA. [cite: 2026-01-22]

#### Browser Specifics (Firefox) [cite: 2026-01-22]
Firefox does not use the System Trust Store. You must import it manually: [cite: 2026-01-22]
1. Settings → Privacy & Security. [cite: 2026-01-22]
2. Scroll to **Certificates** → **View Certificates**. [cite: 2026-01-22]
3. Under the **Authorities** tab, click **Import**. [cite: 2026-01-22]
4. Select `root_ca.crt` and check **"Trust this CA to identify websites"**. [cite: 2026-01-22]

---

## 2. SMTP Alert Pipeline (msmtp) [cite: 2026-01-22]

To ensure you receive high-priority backup and health alerts, verify your Freedom.nl SMTP connection. [cite: 2026-01-22]

### 2.1 Test Connection [cite: 2026-01-22]
Run the following command on your Pi to send a test email: [cite: 2026-01-22]

    echo "Sovereign Stack: SMTP Test Successful" | msmtp your-email@freedom.nl

### 2.2 Troubleshooting [cite: 2026-01-22]
If the email does not arrive: [cite: 2026-01-22]
- Check the logs: `tail -f ${DOCKER_ROOT}/backups/cron.log` [cite: 2026-01-22]
- Verify your app-specific password in the `.env` file. [cite: 2026-01-22]

---

## 3. Nextcloud Talk: STUN/TURN Configuration [cite: 2026-01-22]

To enable video calls outside your local network, you must connect the Coturn service to Nextcloud. [cite: 2026-01-22]

1. Log in to your **Nextcloud** as an admin. [cite: 2026-01-22]
2. Go to **Administration Settings** → **Talk**. [cite: 2026-01-22]
3. Under **STUN servers**, add: [cite: 2026-01-22]
   - `yourdomain.com:3478` [cite: 2026-01-22]
4. Under **TURN servers**, add: [cite: 2026-01-22]
   - Server: `yourdomain.com:3478` [cite: 2026-01-22]
   - Secret: (Use the `COTURN_SECRET` from your `.env`) [cite: 2026-01-22]
   - Protocol: `UDP and TCP` [cite: 2026-01-22]

---

## 4. Backup Target: Wake-on-LAN Preparation [cite: 2026-01-22]

The backup pipeline includes a "Wake-up" logic to ensure your remote workstation is online. [cite: 2026-01-22]

1. **BIOS/UEFI:** Ensure "Wake on LAN" or "Power on by PCI-E" is enabled on your backup PC. [cite: 2026-01-22]
2. **Windows Settings:** In Device Manager, find your Network Adapter → Properties → Power Management → Enable "Allow this device to wake the computer" and "Only allow a magic packet to wake the computer". [cite: 2026-01-22]
3. **MAC Address:** Verify that the `PC_MAC` in your `.env` matches the address found in your Fritz!Box or via `ipconfig /all`. [cite: 2026-01-22]

---

## 5. Summary of Automated Tasks [cite: 2026-01-22]
- **Backups:** Run daily at `03:00`. [cite: 2026-01-22]
- **Dead Man's Switch:** Verifies integrity and remote arrival at `04:30`. [cite: 2026-01-22]
- **Container Updates:** Watchtower checks for security patches every 24 hours. [cite: 2026-01-22]

---

## 6. Homarr Dashboard Setup [cite: 2026-01-22]

After starting the stack, your Homarr dashboard will be empty. Follow these steps to populate it: [cite: 2026-01-22]

1. **Access the Dashboard:** Go to `http://<your-pi-ip>:7575` or your domain. [cite: 2026-01-22]
2. **Enter Edit Mode:** Click the pencil icon in the top right corner. [cite: 2026-01-22]
3. **Docker Integration:** Enable "Docker Integration" on your tiles to automatically see CPU and RAM usage for your containers. [cite: 2026-01-22]
4. **Health Pings:** For internal health checks, use the service names defined in `docker-compose.yaml` (e.g., `http://adguardhome`). [cite: 2026-01-22]
5. **Custom Icons:** Upload your own sovereign-stack icons to `/app/public/icons` within the container. [cite: 2026-01-22]
