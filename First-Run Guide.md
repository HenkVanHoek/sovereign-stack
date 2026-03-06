# First-Run Guide: Service Configuration & Trust (v4.3.0)

This guide covers the essential post-installation steps to ensure your **sovereign-stack** services are trusted, connected, and fully functional.

---

## 1. Certificate Strategy: Public vs. Internal Trust

The Sovereign Stack is designed to support a **Dual Certificate Strategy** using Nginx Proxy Manager (NPM):

**A. Public CAs (Let's Encrypt / Commercial CAs)**
For outward-facing services (Nextcloud, Vaultwarden, Forgejo), use the free **Let's Encrypt** integration built into NPM. This ensures that any device trusts your server out-of-the-box.

**B. Private Internal CA (Step-CA)**
For internal services not exposed to the internet, Sovereign Stack provides its own Certificate Authority (Step-CA). To trust these, you must install the Sovereign Root Certificate.

### 1.1 Export the Root Certificate
Run this on your Pi to prepare the certificate for transfer:

    cp ${DOCKER_ROOT}/step-ca/certs/root_ca.crt ~/root_ca.crt

Transfer this file to your device via SFTP or USB.

### 1.2 Installation per Device Type
* **Windows:** Double-click root_ca.crt → Install Certificate → Local Machine → Place in "Trusted Root Certification Authorities".
* **Android:** Settings → Security → Encryption & credentials → Install a certificate → CA certificate.
* **iOS:** Settings → General → About → Certificate Trust Settings → Enable full trust for the Sovereign Root CA.

---

## 2. DNS Strategy: Split-Horizon Configuration

To ensure seamless access at home and on the road, follow the Split-Horizon approach.

### 2.1 External DNS (Public)
At your domain provider (e.g., Freedom Internet), set these records:
* **A Record:** Host @ → points to your Public WAN IP.
* **CNAME Record:** Host * → points to your root domain (e.g., piselfhosting.com).

### 2.2 Internal DNS (AdGuard Home)
Inside your network, bypass the internet for better speed and reliability:
1. Access AdGuard Home at http://adguardhome:3000.
2. Go to **Filters → DNS Rewrites**.
3. Add: *.yourdomain.com → IP: 192.168.178.x (Your Pi's internal IP).

---

## 3. Mail Architecture & Alerts

The stack uses two separate paths for email notifications.

### 3.1 Host-Level Alerts (msmtp)
System alerts (Backups, Fail2ban) use the forwarder on the Pi host. Verify the connection:

    echo "Sovereign Stack: Host Alert Test" | msmtp your-email@provider.com

### 3.2 Container SMTP
Services like Nextcloud connect directly to smtp.soverin.net via credentials in the .env file. Verify this in **Nextcloud Settings → Basic Settings → Email**.

---

## 4. Nextcloud Specialized Services

### 4.1 Talk (STUN/TURN)
To enable video calls outside your network, connect the Coturn service:
* **STUN server:** turn.yourdomain.com:3478
* **TURN server:** turn.yourdomain.com:3478 (Use COTUR_SECRET from .env).

### 4.2 High Performance Backend (Notify Push)
1. **NPM:** Add custom location ^~ /push/ to your Nextcloud host. Forward to notify-push:7867.
2. **Activate:**

    docker exec --user 33 nextcloud-app php occ app:enable notify_push
    docker exec --user 33 nextcloud-app php notify_push:setup [https://nextcloud.yourdomain.com/push](https://nextcloud.yourdomain.com/push)

---

## 5. Infrastructure Discovery (NetBox)

The Sovereign Stack automatically maps your infrastructure to NetBox.
1. **Initialize:** Run ./run_task.sh python3 infra_scanner.py.
2. **Superuser:** Create your admin account for the UI:

    docker exec -it netbox /opt/netbox/netbox/manage.py createsuperuser

---

## 6. Matrix Architecture (Post-ADR 0001)

Following **ADR 0001**, local Matrix hosting (Conduit) has been removed.
1. Traffic for matrix.yourdomain.com should be routed via NPM to your external Synapse node.
2. Verify the federation endpoint:
   curl -v [https://matrix.yourdomain.com/.well-known/matrix/server](https://matrix.yourdomain.com/.well-known/matrix/server)

---

## 7. Homarr Dashboard Integration

| Service | Internal Docker URL | Official Source |
| :--- | :--- | :--- |
| **Homarr** | http://homarr:7575 | [https://homarr.dev](https://homarr.dev) |
| **Nextcloud** | http://nextcloud-app:80 | [https://nextcloud.com](https://nextcloud.com) |
| **Vaultwarden** | http://vaultwarden:80 | [https://github.com/dani-garcia/vaultwarden](https://github.com/dani-garcia/vaultwarden) |
| **Forgejo** | http://forgejo:3000 | [https://forgejo.org](https://forgejo.org) |
| **NetBox** | http://netbox:8085 | [https://netboxlabs.com](https://netboxlabs.com) |
| **AdGuard Home** | http://adguardhome:3000 | [https://adguard.com/adguard-home.html](https://adguard.com/adguard-home.html) |
| **Home Assistant** | http://homeassistant:8123 | [https://home-assistant.io](https://home-assistant.io) |
| **Frigate** | http://frigate:5000 | [https://frigate.video](https://frigate.video) |
| **UniFi** | https://unifi:8443 | [https://ui.com](https://ui.com) |
| **Signal-API** | http://signal-api:8080 | [https://github.com/bbernhard/signal-cli-rest-api](https://github.com/bbernhard/signal-cli-rest-api) |

---

## 8. Verifying the Sovereign Guards

Perform a manual "Pre-flight" check to ensure integrity:
1. **The Sentinel:** Run ./verify_env.sh. It must exit silently.
2. **Identity Guard:** Try running ./backup_stack.sh with sudo. It should be blocked.
3. **The Janitor:** Check if S3 mounts have correct permissions (UID 33/1000).

---
*This documentation is part of the Sovereign Stack project.
Copyright (c) 2026 Henk van Hoek. Licensed under the GNU GPL-3.0.*
