# First-Run Guide: Service Configuration & Trust (v4.1)

This guide covers the essential post-installation steps to ensure your **sovereign-stack** services are trusted, connected, and fully functional.

---

## 1. Certificate Strategy: Public vs. Internal Trust

The Sovereign Stack is designed to support a **Dual Certificate Strategy** using Nginx Proxy Manager (NPM):

**A. Public CAs (Let's Encrypt / Commercial CAs)**
For outward-facing services (Nextcloud, Vaultwarden, Matrix), it is highly recommended to use the free **Let's Encrypt** integration built into NPM, or import your own purchased CA certificates. This ensures that any device (like your friends' smartphones) trusts your server out-of-the-box without manual configuration.

**B. Private Internal CA (Step-CA)**
For internal, highly secure services that are *not* exposed to the internet, Sovereign Stack provides its own Certificate Authority (Step-CA). If you choose to secure internal nodes with this CA, your devices will not recognize the local SSL certificates by default. You must install the Sovereign Root Certificate on every device that accesses these specific internal endpoints.

### 1.1 Export the Root Certificate (For Step-CA usage only)
If you are utilizing Step-CA for internal routing, you need to get the `root_ca.crt` file from your Raspberry Pi to your computer or phone. Run this on your Pi:

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
   - `turn.yourdomain.com:3478`
4. Under **TURN servers**, add:
   - Server: `turn.yourdomain.com:3478`
   - Secret: (Use the `COTUR_SECRET` from your `.env`)
   - Protocol: `UDP and TCP`

---

## 4. Nextcloud High Performance Backend (Notify Push)

To enable instant file syncing and heavily reduce the load on your Raspberry Pi, the Notify Push container requires specific routing in Nginx Proxy Manager (NPM) and a final setup command in Nextcloud.

### 4.1 Nginx Proxy Manager Configuration
1. Open your NPM dashboard and edit your Nextcloud proxy host (`nextcloud.yourdomain.com`).
2. Go to the **Custom locations** tab.
3. Click **Add location** and enter the following details:
   - **Location:** `^~ /push/`
   - **Scheme:** `http`
   - **Forward Hostname / IP:** `notify-push`
   - **Forward Port:** `7867`
4. Click the gear icon next to the location to open custom configuration and add the following websocket headers:
   `proxy_set_header Upgrade $http_upgrade;`
   `proxy_set_header Connection "Upgrade";`
5. Click **Save**.

### 4.2 Nextcloud App Activation
Once the routing is active, initialize the app inside the Nextcloud container using the correct permissions (UID 33 for `www-data`):

    docker exec --user 33 nextcloud-app php occ app:enable notify_push
    docker exec --user 33 nextcloud-app php occ notify_push:setup [https://nextcloud.yourdomain.com/push](https://nextcloud.yourdomain.com/push)

If successful, the output will confirm that the push server is configured correctly.

---

## 5. Backup Target: Wake-on-LAN Preparation

The backup pipeline includes `wake_target.sh` logic to ensure your remote workstation is online.

1. **BIOS/UEFI:** Ensure "Wake on LAN" or "Power on by PCI-E" is enabled on your backup PC.
2. **Windows Settings:** In Device Manager, find your Network Adapter → Properties → Power Management → Enable "Allow this device to wake the computer" and "Only allow a magic packet to wake the computer".
3. **MAC Address:** Verify that `BACKUP_TARGET_MAC` in your `.env` matches the address found in your router or via `ipconfig /all`.
4. **Path Notation:** For Windows targets, use the `/DRIVE:/path` format (e.g., `/H:/BackupsPi`) to ensure compatibility with SFTP and the monitor script.

---

## 6. Summary of Automated Tasks
- **Backups:** Run daily at `03:00` via `backup_stack.sh`.
- **Dead Man's Switch:** Verifies integrity and remote arrival at `03:30` via `monitor_backup.sh`.
- **Container Updates:** Watchtower checks for security patches every 24 hours.

---

## 7. Matrix (Conduit & Synapse)

Matrix is the Sovereign Stack's recommended protocol for replacing WhatsApp/Signal.

1.  **Federation Verification:**
    Run this command on your workstation to verify your proxy settings:
    `curl -v https://matrix.yourdomain.com/.well-known/matrix/server`
    *You should see a JSON response pointing to port 443.*

2.  **Architecture Note:**
    If you are running the lightweight **Conduit** container on your Pi for a small group, you can register via an app like Element. If you are serving a large community (1000+ users), you should externalize **Synapse** to a heavier Intel node, routing traffic to it via the Pi's Nginx Proxy Manager.

---

## 8. Netbox Setup & Initialization

Netbox requires specific directories and a superuser to function correctly.

**1. Pre-installation: Directory Setup**
Run the following commands from your project root before starting the stack:

    cd ~/docker
    mkdir -p netbox/media netbox/reports netbox/scripts netbox/db
    sudo chown -R 1000:1000 netbox/media netbox/reports netbox/scripts

**2. Post-installation: Create Superuser**
Once the Netbox container is fully running, create your administrator account:

    docker exec -it netbox /opt/netbox/netbox/manage.py createsuperuser

Follow the interactive prompts to set your username, email, and password.

---

## 9. Homarr Dashboard Setup

After starting the stack, your Homarr dashboard will be empty. Follow these steps to populate it:

1. **Access the Dashboard:** Go to `http://<your-pi-ip>:7575` or your domain.
2. **Enter Edit Mode:** Click the pencil icon in the top right corner.
3. **Docker Integration:** Enable "Docker Integration" on your tiles to automatically see CPU and RAM usage for your containers.
4. **Health Pings:** For internal health checks, use the service names defined in `docker-compose.yaml` (e.g., `http://adguardhome:3000`).

---

## 10. Homarr Service Integration Reference (v4.1)

| Service                 | Icon Name             | Internal Docker URL         | Official Website                                                     |
|:------------------------|:----------------------|:----------------------------|:---------------------------------------------------------------------|
| **Nextcloud** | `nextcloud`           | `http://nextcloud-app:80`   | [nextcloud.com](https://nextcloud.com)                               |
| **Collabora**           | `libreoffice`         | `http://collabora:9980`     | [collaboraoffice.com](https://collaboraoffice.com)                   |
| **Forgejo**             | `forgejo`             | `http://forgejo:3000`       | [forgejo.org](https://forgejo.org)                                   |
| **Matrix (Conduit)**    | `matrix`              | `http://matrix:6167`        | [conduit.rs](https://conduit.rs)                                     |
| **AdGuard Home**        | `adguard-home`        | `http://adguardhome:3000`   | [adguard.com](https://adguard.com)                                   |
| **Vaultwarden**         | `bitwarden`           | `http://vaultwarden:80`     | [bitwarden.com](https://bitwarden.com)                               |
| **Home Assistant**      | `home-assistant`      | `http://homeassistant:8123` | [home-assistant.io](https://home-assistant.io)                       |
| **Frigate**             | `frigate`             | `http://frigate:5000`       | [frigate.video](https://frigate.video)                               |
| **Portainer**           | `portainer`           | `http://portainer:9000`     | [portainer.io](https://portainer.io)                                 |
| **Nginx Proxy Manager** | `nginx-proxy-manager` | `http://npm:81`             | [nginxproxymanager.com](https://nginxproxymanager.com)               |
| **Netbox**              | `netbox`              | `http://netbox:8085`        | [netboxlabs.com](https://netboxlabs.com)                             |
| **Glances**             | `glances`             | `http://glances:61208`      | [nicolargo.github.io/glances/](https://nicolargo.github.io/glances/) |

### 10.1 Saving your Layout
To ensure your dashboard configuration is safe, export your layout via **Management → Boards → Export**. Save this as `homarr_layout.json` in your project root.

---

## 11. Verifying the Sovereign Guards

To ensure your stack is correctly protected, you can perform a manual "Pre-flight" check:

1. **Environment Test:** Run `./verify_env.sh` manually. It should exit silently if everything is correct.
2. **Identity Guard:** Attempt to run `./backup_stack.sh` with `sudo`. The script should immediately block the execution and exit with an error.
3. **Anti-Stacking:** Open two terminals and attempt to run `./monitor_backup.sh` simultaneously. The second instance should exit immediately thanks to the `flock` protection.

---

---

*This documentation is part of the **Sovereign Stack** project. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. Copyright (c) 2026 Henk van Hoek. Licensed under the [GNU GPL-3.0 License](LICENSE).*
