# Troubleshooting sovereign-stack

## 1. Browser remembers old certificate (HSTS)
If you recently changed your SSL certificate (e.g., from Let's Encrypt to Smallstep) and the browser shows a security warning, you must clear the HSTS cache.

### Chrome / Edge / Brave
1. Navigate to `chrome://net-internals/#hsts`
2. Under **"Delete domain security policies"**, enter your domain: `home.piselfhosting.com`
3. Click **"Delete"**.

### Firefox
1. Open History (`Ctrl + Shift + H`).
2. Right-click on the domain and select **"Forget About This Site"**.

---

## 2. NPM Certificate Mismatch
If the browser shows an "Invalid Certificate" error, ensure that the correct certificate is selected in the Nginx Proxy Manager UI:
`Proxy Hosts` -> `Edit` -> `SSL` -> `SSL Certificate`.

---

## 3. External IP detected via VPN (Wireguard)
When using Wireguard, NPM may see your public WAN IP instead of your internal VPN IP.

### Diagnosis
Check which client IP is being blocked by searching for 403 errors in the logs:

    docker exec -it npm cat /data/logs/proxy-host-X_access.log | grep 403

### Solution
Add your public static IPv4 address to the **NPM Access List**. This ensures access is granted even when traffic is masqueraded through the public gateway.

---

## 4. Permission Denied on Step-CA
If `step-ca` fails to start with a 'Permission denied' error, the host directory requires UID 1000 ownership.

**Fix:**

    sudo chown -R 1000:1000 ${DOCKER_ROOT}/step-ca

---

## 5. Browser Caching & Service Workers
Modern browsers use Service Workers that can persist even after a restart, causing 'Fetch Errors' after environment changes.

### Recovery Steps:
1. Fully log out of the service (e.g., Vaultwarden/Nextcloud).
2. Open Developer Tools (`F12`) -> **Application** -> **Clear Storage** -> **Clear Site Data**.
3. Perform a hard refresh (`Ctrl + F5`).

---

## 6. Firewall: Subnet Mask Precision
When configuring **UFW** to allow traffic from Docker to host-mode services (like Home Assistant), use the `/12` mask.

**Command:**

    sudo ufw allow from 172.16.0.0/12 to any

---

## 7. Prosody: "No channel binding" in Conversations (Android)
When using Prosody behind a reverse proxy like Nginx Proxy Manager (NPM), Android clients (specifically Conversations) might fail to connect with the error message "No channel binding".

### Cause
This happens because Conversations attempts to use `SCRAM-SHA-1-PLUS` or `SCRAM-SHA-256-PLUS`. These mechanisms use "Channel Binding" to verify that the TLS connection hasn't been intercepted. Since NPM terminates the TLS connection, the session binding seen by the phone does not match what Prosody sees.

### Solution
Disable the "PLUS" SASL mechanisms in your Prosody configuration. This forces the client to use standard SCRAM authentication, which is secure but does not require channel binding.

1. Edit your `prosody.cfg.lua` using `vi`:

    vi ${DOCKER_ROOT}/prosody/config/prosody.cfg.lua

2. Add or update the `sasl_forbidden_mechanisms` setting:

    -- Disable PLUS mechanisms to support TLS termination via Nginx Proxy Manager
    sasl_forbidden_mechanisms = { "SCRAM-SHA-1-PLUS", "SCRAM-SHA-256-PLUS" }

3. Restart the Prosody container:

    docker compose restart prosody
