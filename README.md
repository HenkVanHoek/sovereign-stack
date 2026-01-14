# sovereign-stack: Sovereign Home Infrastructure

sovereign-stack is a project dedicated to regaining digital sovereignty by hosting essential services on a local Raspberry Pi. This project provides a blueprint for an independent, secure, and privacy-first "Digital Gold Reserve."

## Core Vision
* **Sovereignty:** Reducing dependency on US-based infrastructure (e.g., Let's Encrypt, Big Tech clouds).
* **Privacy:** Keeping community and personal data (GDPR) within your own walls.
* **IoT Autonomy:** Utiliz# sovereign-stack: Simplified Digital Sovereignty

This project provides a reliable, privacy-first home infrastructure 
running on a Raspberry Pi. It prioritizes stability and ease of 
management while maintaining full control over personal data.

## Core Components
* **DNS Privacy:** AdGuard Home using trusted Freedom Internet DNS.
* **Password Management:** Vaultwarden for secure, local credential storage.
* **Access Control:** Nginx Proxy Manager (NPM) with IP-based Access Lists.
* **Communication:** Prosody XMPP server for private messaging.
* **Security:** All surveillance traffic (Frigate) isolated from the internet.

## Network Configuration (Simplified)
To keep the infrastructure manageable, the following logic is applied:
1. **DNS Resolving:** AdGuard Home acts as the primary resolver, 
   forwarding external queries to Freedom Internet's private servers.
2. **Local Traffic:** DNS Rewrites are used within AdGuard to route 
   `*.piselfhosting.com` traffic directly to the Raspberry Pi IP.
3. **VPN Access:** Infrastructure management (NPM/Portainer) is 
   restricted to local or VPN (Wireguard) connections only.

## Maintenance
* **Updates:** Managed automatically by Watchtower.
* **Monitoring:** Real-time logs available via Portainer.ing hardware (like CCTV) without allowing it to "phone home" to foreign servers.
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
| **Portainer** | Container management                         | Manage the containers running the system |

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
## Step-CA: Internal Trust Management
The stack now operates its own Private CA. This ensures that even 
without an internet connection, all internal traffic remains encrypted 
and trusted.

### Configuration Details:
- **ACME Endpoint:** `https://step-ca:9000/acme/acme/directory`
- **Fingerprint:** Stored in `.env` for automated provisioning.
- **Protocol:** ACME v2.

### Client Trust:
To trust this CA, the `root_ca.crt` must be imported into the 
OS-level trust store on all client devices.
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

## AdGuard: DNS-over-TLS Configuration
To ensure reliable and encrypted DNS lookups via Freedom Internet, 
IP-based TLS strings are used. This avoids 'bootstrap loops' 
where the system cannot resolve the DNS provider's own hostname.

### Configuration:
* **Upstream:** `tls://185.93.175.43` and `tls://185.232.98.76`
* **Protocol:** Port 853 (DoT)
* **Bootstrap:** Local Freedom IPs are used for initial resolution
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
## Services: Sovereign Communication (Prosody)
    The stack includes a Prosody XMPP server to provide private, 
    decentralized messaging within the local infrastructure.

    ### Encryption:
    - Secured via **Smallstep CA** certificates.
    - Configuration utilizes the `./prosody/certs` volume to inject 
      locally generated SSL files.

    ### Network Hardening:
    - Client access (5222) is restricted to the trusted local subnet 
      via UFW.
    - BOSH and Websocket ports (5280/5281) are available for web-based 
      XMPP clients.

    The stack includes a functional Prosody XMPP server for private 
    messaging, independent of commercial providers.

    ### Current Setup:
    - **Users:** Primary administrator and family accounts active.
    - **Encryption:** TLS-enforced for all client connections.
    - **Ports:** 5222 (c2s) and 5269 (s2s) managed via UFW.

    ### Mobile Integration:
    - **Android:** Recommended client is **Conversations** (via F-Droid).
    - **Logic:** Connects to `chat.piselfhosting.com` using DNS 
      rewrites provided by AdGuard Home when local, or VPN when mobile.
---
## Maintenance: Encrypted Backups
    The `backup_stack.sh` script automates the backup of the entire 
    Docker environment, including volumes and configuration files.

    ### Features:
    - **AES-256 Encryption:** All backups are encrypted using OpenSSL 
      with PBKDF2 for high security.
    - **GitHub Ready:** Sensitive data is pulled from the `.env` file; 
      no passwords or personal paths are stored in the script.
    - **Automated Rotation:** Maintains a rolling window of backups 
      (default: 7 days) to manage disk space.

    ### Configuration:
    Add the following to your `.env` file:
    - `BACKUP_PASSWORD`: The key used for encryption.
    - `BACKUP_RETENTION_DAYS`: Number of files to keep.

    ### Manual Run:
    `./backup_stack.sh`

---
## Automation: Scheduled Backups
    To ensure data persistence and disaster recovery readiness, the 
    backup process is fully automated via Cron.

    ### Schedule:
    - **Frequency:** Daily at 03:00 AM.
    - **Command:** `cd /home/hvhoek/docker && ./backup_stack.sh`
    - **Integrity:** Each backup is a timestamped, AES-256 encrypted 
      archive of the entire project root.

    ### Verification:
    Periodically check the `${DOCKER_ROOT}/backups` directory to 
    confirm that new `.enc` files are being generated successfully.

---
## Monitoring: Generic Watchdog Implementation
    The monitoring system is decoupled from specific user paths and 
    identities to allow for secure repository distribution.

    ### Configuration (via .env):
    - `BACKUP_EMAIL`: Target for alerts (e.g., your Freedom.nl address).
    - `MONITOR_WINDOW_MINS`: Time window to check for new files 
      (default: 90).

    ### Portability:
    The `monitor_backup.sh` script dynamically resolves its own 
    absolute path using `readlink`, ensuring the `.env` file is 
    located correctly even when triggered by the system Cron daemon.

    ### Fail-Safe:
    By running this script independently of the backup process, the 
    system provides a 'Dead Man's Switch' that triggers if the 
    primary backup script fails to execute entirely.

---
## Maintenance: Monitoring Permissions
    The monitoring system is designed to run under a standard user 
    account (non-root) to enhance system security.

    ### Setup Requirements:
    - **Permissions:** Ensure the monitor script is executable:
      `chmod +x monitor_backup.sh`
    - **Ownership:** The user must have read access to the 
      `${DOCKER_ROOT}/backups` directory.
    - **Cron:** Schedule via the user crontab (`crontab -e`) to 
      avoid unnecessary sudo escalation.

---
## Security: Network Hardening (UFW)
    The Raspberry Pi utilizes UFW (Uncomplicated Firewall) to implement 
    a 'Default Deny' incoming policy.

    ### Open Ports:
    - **80/443 (TCP):** Web traffic orchestrated by NPM.
    - **53 (TCP/UDP):** DNS resolution handled by AdGuard Home.
    - **9000 (TCP):** Internal ACME endpoint for Step-CA.
    - **22 (TCP):** SSH management (restricted to local/VPN).

    ### Docker Integration:
    Note that Docker manages its own iptables chains. This UFW 
    configuration acts as the primary host-level gatekeeper, while 
    NPM Access Lists provide a secondary application-level filter.

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
---
## Utilities: Sovereign Certificate Generator
    The `gen_cert.sh` script provides a portable way to manually issue 
    certificates from the internal Smallstep CA. This is particularly 
    useful when the proxy manager UI does not support custom ACME 
    fields or for long-lived certificates (e.g., 10 years).

    ### Features
    - **GitHub Safe:** No personal emails or usernames are hardcoded. 
      It dynamically pulls identity from `.env`.
    - **Permission Aware:** Automatically sets file ownership to the 
      active host user using dynamic UID/GID detection.
    - **Cleanup:** Automatically removes the private key from the 
      container's temporary storage after the transfer is complete.

    ### Usage
    1. Ensure `STEPCA_EMAIL` is set in your `.env` file.
    2. Run the script: `./gen_cert.sh`.
    3. Follow the prompts for domain and duration.
    4. Upload the resulting `.crt` and `.key` files to your proxy.
---
## License
This project is shared for educational purposes in the spirit of digital autonomy.
