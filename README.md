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

## Why Sovereignty Matters
As of late 2025, major European free ACME providers (like Buypass) have terminated their services. This project implements **Smallstep** as a response, allowing users to become their own Certificate Authority. Furthermore, it addresses the "IoT Leak" by ensuring that devices like security cameras cannot communicate with external servers, keeping sensitive visual data under the sole control of the owner.

---

## License
This project is shared for educational purposes in the spirit of digital autonomy.
