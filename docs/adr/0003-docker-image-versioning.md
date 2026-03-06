# Sovereign Stack Architecture Decision Record

# License: GNU General Public License v3.0 or later.
# Copyright (c) 2026 Henk van Hoek

# ADR 0003: Docker Image Versioning and Update Strategy

Status: Accepted
Date: 2026-03-05

Context:
    The Sovereign Stack relies on a wide array of Docker containers. Relying
    exclusively on the `:latest` tag for all services introduces severe risks.
    Unattended automated updates can cause catastrophic data corruption if a
    database engine performs a major version bump without a manual schema
    migration. Furthermore, some upstream projects (like Frigate) explicitly
    refuse to publish a `:latest` tag to prevent automated systems from
    pulling breaking changes.

Decision:
    To guarantee the integrity and stability of the Sovereign Stack, the
    following versioning rules are strictly enforced in `docker-compose.yaml`:

    1. Stateful Backends & Databases: MUST use specific major/minor version
       tags. The `:latest` tag is strictly forbidden.
       - Examples: `mariadb:10.11`, `postgres:15-alpine`, `mongo:7.0`.
    2. Hardware-Coupled & Complex Services: MUST use explicit version tags
       or the `:stable` tag if upstream provides it.
       - Examples: `frigate:stable`, `garage:v0.9.1`, `forgejo:14`.
    3. Stateless or Auto-Migrating Frontends: May utilize the `:latest` tag
       ONLY IF the upstream maintainers have a proven track record of safe,
       backward-compatible rolling releases.
       - Examples: `vaultwarden/server:latest`, `nginx-proxy-manager:latest`.
    4. The Watchtower Guardian: Any service categorized under Rule 1 or 2
       MUST include the label `com.centurylinklabs.watchtower.enable=false`.

Rationale:
    Pinning database versions prevents silent schema corruption. Using `:stable`
    for Frigate ensures compatibility with specific AI models and hardware
    passthrough configurations. Disabling Watchtower for core infrastructure
    ensures that updates are an intentional, administrator-driven process,
    aligning with the core philosophy of digital sovereignty.

Consequences:
    - Increased reliability and zero unexpected downtime for critical services.
    - Requires intentional, manual intervention by the administrator to upgrade
      databases (e.g., dumping data, bumping the YAML tag, importing data).
    - Prevents the "manifest unknown" error during automated pulls for services
      that omit the `:latest` tag.
