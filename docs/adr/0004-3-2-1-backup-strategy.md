# Sovereign Stack Architecture Decision Record

# License: GNU General Public License v3.0 or later.
# Copyright (c) 2026 Henk van Hoek

# ADR 0004: 3-2-1 Backup Strategy Implementation

Status: Accepted
Date: 2026-03-18

Context:
    Data loss can occur at any time due to hardware failure, human error,
    ransomware, or natural disasters. The Sovereign Stack hosts critical
    services including Nextcloud, Matrix/Synapse, and NetBox with valuable
    user data and configurations. A robust backup strategy is essential to
    ensure business continuity and data sovereignty.

Decision:
    The Sovereign Stack implements the industry-standard 3-2-1 backup strategy:

    3 Copies of Data:
        1. Original: The live Docker environment at /home/$USER/docker
        2. Local Backup: Encrypted archive on USB drive (BACKUP_LOCAL_TARGET)
        3. Off-site Backup: Encrypted archive on NAS/remote target (BACKUP_OFFSITE_*)

    2 Different Storage Media:
        - Primary storage: NVMe M.2 SSD on Raspberry Pi 5
        - Backup storage: External USB drive (8TB recommended)

    1 Off-site Copy:
        - Remote NAS accessible via Tailscale VPN
        - Wakes automatically via Wake-on-LAN before backup

    Implementation Details:
        1. Backup Script (backup_stack.sh):
           - Creates encrypted tar archive (AES-256-CBC)
           - Includes MariaDB database dumps
           - Includes Synapse VM data via Tailscale
           - Excludes large media files (Frigate recordings, logs, cache)
        2. Encryption:
           - All backups encrypted with AES-256-CBC + PBKDF2
           - Password stored in BACKUP_ENCRYPTION_KEY
        3. Retention:
           - Local: BACKUP_LOCAL_RETENTION_DAYS (default: 7 days)
           - Off-site: BACKUP_OFFSITE_RETENTION_VERSIONS (default: 3 versions)
        4. Verification:
           - monitor_backup.sh verifies local archive integrity
           - Compares SHA256 checksums between local and off-site copies
           - Reports status via email/Signal

Rationale:
    The 3-2-1 strategy is the gold standard for backup reliability:
    - Protection against local hardware failure (USB copy)
    - Protection against site-wide disasters (off-site NAS)
    - Encryption protects against theft of backup media
    - Automation ensures backups are not forgotten
    - Verification ensures backup integrity can be trusted

Consequences:
    - Administrator must maintain off-site backup target (NAS)
    - Initial backup may take significant time depending on data size
    - Encrypted backups require password management
    - Off-site backup depends on reliable network connectivity
    - 3-2-1 strategy does not protect against logical errors (e.g., if
      a corrupted file is backed up before detection)

Related Decisions:
    - ADR 0001: Removal of Matrix Conduit (Matrix requires database backups)
    - ADR 0003: Docker Image Versioning (Watchtower disabled for core services)

References:
    - Veeam 3-2-1 Backup Rule: https://www.veeam.com/blog/321-backup-rule-3-2-1.html
    - NIST SP 800-34: Contingency Planning Guide for Information Technology Systems
