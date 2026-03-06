# ADR 0002: Infrastructure Discovery and Storage Abstraction

Status: Accepted
Date: 2026-03-05

Context:
    As the Sovereign Stack evolved, manual inventory management became
    unsustainable. Hardcoded storage paths also limited hardware
    portability and redundancy.

Decision:
    1. Implement Netbox as the central Single Source of Truth (SSoT).
    2. Introduce automated SSH discovery via infra_scanner.py.
    3. Abstract storage using S3-compatible APIs (Garage/Rclone) for
       off-site snapshots and media resilience.

Rationale:
    Automation reduces configuration drift. Storage abstraction allows
    for hardware-independent deployments, critical for long-term
    data sovereignty and disaster recovery.
