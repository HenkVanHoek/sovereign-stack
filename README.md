# SovereignStack v2.1: The Digital Gold Reserve

SovereignStack is a project dedicated to regaining digital autonomy by hosting essential services on a local Raspberry Pi 5. It provides a professional blueprint for an independent, secure, and privacy-first infrastructure, serving as the reference model for the **PiSelfhosting** project.

---

## 1. Core Vision & Philosophy

* **Sovereignty:** Reducing dependency on centralized infrastructure and foreign "cloud" providers.
* **Privacy:** Keeping community and personal data (GDPR) within your own physical walls.
* **IoT Autonomy:** Utilizing hardware (CCTV/Smart Home) without allowing it to "phone home" to external servers.
* **Resilience:** Services remain functional and trusted even if external certificate authorities or providers fail.

---

## 2. Prerequisites & Hardware

### Recommended Hardware
- **Host:** Raspberry Pi 5 (8GB recommended).
- **Storage:** 1TB M.2 SSD (NVMe) for high I/O reliability and longevity.
- **Cooling:** Active cooling required (Proportional fan control target: ~57°C).

### Software Environment
- **OS:** Raspberry Pi OS 64-bit.
- **Docker Engine & Compose:**
    ```bash
    curl -sSL [https://get.docker.com](https://get.docker.com) | sh
    sudo usermod -aG docker $USER
    ```
- **Dependencies:** `msmtp` (alerts), `iptables` (firewall), `curl` (healthchecks).

---

## 3. Network Topology (Security in Layers)

The stack employs three distinct network zones to ensure maximum isolation and performance:

### Zone 1: pi-services (Public/Frontend Bridge)
The primary communication layer. The Reverse Proxy (`npm`) routes traffic via internal Docker DNS.
- **Services:** `npm`, `homarr`, `vaultwarden`, `adguardhome`, `prosody`, `frigate`, `portainer`, `step-ca`, `watchtower`.

### Zone 2: nextcloud-internal (Isolated Backend)
A strictly internal network (`internal: true`) for the Nextcloud data-tier. No external internet access.
- **Services:** `nextcloud-db`, `nextcloud-redis`, `nextcloud-app` (Dual-homed).

### Zone 3: Host Mode (System Access)
Services requiring direct interaction with the hardware or host network stack.
- **Services:** `fail2ban` (firewall), `homeassistant` (discovery), `glances` (telemetry).

---

## 4. Core Service Catalog

| Service | Access URL | Purpose |
| :--- | :--- | :--- |
| **Homarr** | `home.piselfhosting.com` | Central Navigation Dashboard |
| **Nginx Proxy Manager** | `http://[Pi-IP]:8181` | Gateway & SSL Termination |
| **Nextcloud** | `cloud.piselfhosting.com` | Private Data & Mail Storage |
| **AdGuard Home** | `dns.piselfhosting.com` | Network-wide DNS Privacy |
| **Vaultwarden** | `vault.piselfhosting.com` | Secure Password Management |
| **Frigate NVR** | `cam.piselfhosting.com` | Local AI Surveillance |
| **Step-CA** | `port 9000` | Sovereign Certificate Authority |
| **Prosody** | `chat.piselfhosting.com` | XMPP Decentralized Messaging |

---

## 5. Security & Active Defense

### Access Control (NPM ACL)
Access is governed by IP-based Whitelisting. The `Satisfy Any` directive ensures seamless access for the local subnet (`192.168.178.0/24`) and authorized static administrative WAN IPs, while challenging all others.

### Fail2Ban Integration
- **Monitoring:** Scans NPM logs for 401/403 errors.
- **Enforcement:** Automatically drops offending IPs at the kernel level via `iptables`.
- **Alerting:** Dispatches real-time incident reports via Freedom.nl SMTP using `action_mwl`.

### Host Firewall (UFW)
A 'Default Deny' policy is active. Only ports 80, 443, 53, 9000, and 22 (restricted) are permitted.

---

## 6. Maintenance & Data Persistence

### Automated Backups (Nightly 03:00)
1. **Encryption:** `backup_stack.sh` creates AES-256 encrypted archives of the project root.
2. **Transfer:** Archives are moved via SFTP to a primary workstation/peer node.
3. **Dead Man's Switch:** `monitor_stack.sh` verifies backup integrity at 04:30 and alerts the administrator if a backup is missing.

### Environment Configuration (.env)
All secrets are centralized in `.env`. 
> **Important:** Always wrap passwords in double quotes (e.g., `DB_PASSWORD="secret"`). For Frigate RTSP, use single quotes if special characters are present.

---

## 7. App-Specific Hardening

### Home Assistant Proxy
To prevent '400 Bad Request' errors, add the proxy subnet to `configuration.yaml`:
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12
