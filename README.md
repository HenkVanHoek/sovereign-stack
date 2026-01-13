# sovereign-stack: Sovereign Home Infrastructure

sovereign-stack is a project dedicated to regaining digital sovereignty by hosting essential services on a local Raspberry Pi. This project provides a blueprint for an independent, secure, and privacy-first "Digital Gold Reserve."

## Core Vision
* **Sovereignty:** Reducing dependency on US-based infrastructure (e.g., Let's Encrypt, Big Tech clouds).
* **Privacy:** Keeping community and personal data (GDPR) within your own walls.
* **IoT Autonomy:** Utilizing hardware (like CCTV) without allowing it to "phone home" to foreign servers.
* **Resilience:** Services remain functional and trusted even if external authorities fail.

---

## Technical Stack
This project runs on a Raspberry Pi using Docker and a unified bridge network (`pi-services`).

| Service                | Purpose                                      | Implementation                      |
|------------------------|----------------------------------------------|-------------------------------------|
| **Nginx Proxy Manager**| Gateway & Traffic Orchestration              | SSL Termination & Access Control    |
| **Smallstep (step-ca)**| Sovereign Certificate Authority              | Local Root of Trust (ACME)          |
| **AdGuard Home** | DNS Filtering & Local Resolution             | Network-wide Privacy                |
| **Vaultwarden** | Self-hosted Password Manager                 | Bitwarden-compatible Backend        |
| **CCTV / NVR** | Local Surveillance Security                  | Local Storage (No Cloud)            |
| **Prosody** | Sovereign Communication                      | XMPP-based Neighborhood Chat        |

---

## Domain & Security Architecture
The system is designed with three distinct security layers to minimize risk and maximize autonomy:

1. **Infrastructure (e.g., infra.example.com):**
   * **High security.** Accessible only via VPN.
   * Secured by **Sovereign SSL** (Smallstep) to avoid external certificate dependency.
2. **Personal (e.g., familyname.nl):**
   * **Medium security.** Publicly accessible for family services.
   * Uses standard SSL (Let's Encrypt).
3. **Community & IoT (e.g., literatuurwijk.nl):**
   * **Hybrid security.** Local web hosting for neighborhood data sovereignty (GDPR).
   * **Maximum Isolation.** Surveillance cameras are blocked from all outbound internet traffic at the router level (Fritz!Box). Video processing and storage happen strictly locally.

---

## Public Exposure vs. VPN Access
While administrative tools (NPM, Portainer) are restricted to VPN access 
only, user-facing services like Vaultwarden can be exposed to the 
public internet to ensure a seamless experience for family members.

### Security Recommendations for Public Access:
* **Disable Signups:** Once all family members have registered, set 
  `SIGNUPS_ALLOWED="false"` to prevent random internet users from 
  creating accounts on your hardware.
* **Mandatory MFA:** Ensure every user activates Multi-Factor 
  Authentication (TOTP) immediately.
* **Fail2Ban:** (Optional but recommended) Implement Fail2Ban to 
  block IP addresses that attempt multiple failed login attempts.
* **SSL Only:** Always enforce HTTPS via Nginx Proxy Manager.

---

## Active Defense: Fail2Ban Integration
To protect public-facing services (like Vaultwarden) from brute-force 
attacks, this stack includes a Fail2Ban service that monitors Nginx 
Proxy Manager logs.

### Implementation Details:
* **Log Monitoring:** Fail2Ban scans `/var/log/npm/proxy-host-*_access.log` 
  for repeated 401/403 errors.
* **Network Security:** Operates in `host` network mode to interact 
  directly with the Linux `iptables` or `nftables` firewall.
* **Policy:** Default policy is 5 failed attempts within 10 minutes 
  results in a 24-hour IP ban.

### Sovereignty Benefit:
Instead of relying on centralized edge-security providers (e.g., Cloudflare), 
the defense is managed locally on the Raspberry Pi, ensuring that even 
security telemetry remains private.

---

## Offsite Redundancy: The Peer-to-Peer Backup
To achieve maximum resilience, this project implements a mutual 
backup strategy between two geographically separated Raspberry Pis.

### Architecture:
* **Connectivity:** A dedicated Wireguard tunnel connects both nodes.
* **Sync Mechanism:** Utilization of Syncthing or BorgBackup for 
  encrypted, offsite data replication.
* **Hardware:** M.2 SSD storage on both nodes for high reliability.

### Benefits:
* **Sovereign Cloud:** No reliance on AWS, Google Drive, or Dropbox 
  for offsite storage.
* **Privacy:** Data is encrypted at rest and in transit using 
  locally managed keys.
* **Mutual Support:** Both nodes act as a failsafe for each other, 
  doubeling the resilience of the family's digital assets.

---
## Deployment Instructions

### 1. Environment Variables (.env)
Never hardcode passwords or personal paths in the `docker-compose.yml`. Instead, create a `.env` file in your root directory to store your environment-specific variables.

**Example `.env` structure:**
```text
DOCKER_ROOT=/home/<user folder>/docker
DOMAIN_INFRA=infra.example.com
DB_PASSWORD="your_secure_password"
STEPCA_PASSWORD="your_ca_password"
```

### 2. Installation
1. Clone this repository.
2. Copy the `.env.example` to `.env` and fill in your local paths and secrets.
3. Launch the stack:
    ```bash
    docker compose up -d
    ```
---

## Vaultwarden: Usage and Security
Once your data is imported from Chrome or LastPass, follow these 
steps to ensure a smooth and secure experience.

### Browser Integration
Install the Bitwarden browser extension and set your 'Self-hosted' 
URL to `https://vault.piselfhosting.com`. The extension will 
automatically prompt to save new credentials.

### Android Integration
Enable the 'Auto-fill service' in the Bitwarden Android app settings 
to allow the app to detect login fields in browsers and other 
mobile applications.

### Hardening (Post-Migration)
To maintain sovereignty and prevent unauthorized users from 
registering on your server, disable new signups in your configuration:
`SIGNUPS_ALLOWED="false"`

---

## Why Sovereignty Matters
As of late 2025, major European free ACME providers (like Buypass) have terminated their services. This project implements **Smallstep** as a response, allowing users to become their own Certificate Authority. Furthermore, it addresses the "IoT Leak" by ensuring that devices like security cameras cannot communicate with external servers, keeping sensitive visual data under the sole control of the owner.

## Sovereign 2FA Strategy
To avoid dependency on US-based identity providers (Google, Microsoft), 
this stack strictly uses open-source TOTP (Time-based One-Time Password) 
standards.

### Tools:
* **App:** Aegis Authenticator (Open Source, Dutch origin).
* **Distribution:** Installed via F-Droid to bypass Google Play Store 
  control and potential forced updates/kill-switches.
* **Backups:** Encrypted local exports stored on the Raspberry Pi, 
  ensuring access to 2FA tokens even if the mobile device or original 
  app provider fails.

### Why this matters:
Identity is the cornerstone of sovereignty. By using local, 
auditable, and offline tools for 2FA, the user remains in control 
regardless of geopolitical shifts or Big Tech policy changes.

---
## The Battle for the Device: Banking vs. Sovereignty
Recent trends show financial institutions blocking devices that utilize 
independent app stores like F-Droid. This is a direct challenge to 
digital sovereignty.

### Mitigation Strategy:
* **Compartmentalization:** Use Android Work Profiles to isolate 
  corporate/banking apps from sovereign open-source tools.
* **Source Transparency:** While F-Droid is preferred for autonomy, 
  using the Play Store version of open-source tools (like Aegis) 
  can be a pragmatic compromise to maintain access to essential 
  financial services without sacrificing the security of the 
  underlying code.

### Philosophical Stance:
True sovereignty means the owner of the hardware decides what software 
runs on it. We reject 'Security by Exclusion' and advocate for 
'Security by Transparency'.

## License
This project is shared for educational purposes in the spirit of digital autonomy.
