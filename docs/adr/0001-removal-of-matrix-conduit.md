# Sovereign Stack Architecture Decision Record

# License:
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
#
# Copyright (c) 2026 Henk van Hoek

# ADR 0001: Removal of Matrix Conduit as Local Home Server

Status: Accepted
Date: 2026-02-17

Context:
    Sovereign Stack originally included Conduit as a lightweight Matrix Home Server
    written in Rust, specifically chosen to minimize resource usage on
    Raspberry Pi 5 hardware. The goal was to provide a fully local,
    private communication layer.

Decision:
    We have decided to remove Conduit from the local Sovereign Stack deployment.

Rationale:
    1. Lack of Mature Administrative Tooling:
        Conduit currently lacks a robust, user-friendly administrative interface.
        Effective management of users, rooms, and server state is critical
        for a Sovereign implementation.
    2. Operational Complexity:
        Despite being lightweight, the management overhead and complexity
        of troubleshooting a Conduit instance proved too high for the
        standardized Sovereign Stack workflow.
    3. Product Maturity:
        The failure to establish a working, reliable administrative tool
        in collaboration with the community indicates that the product
        is not yet mature enough for production-grade use in this stack.

Consequences:
    - Matrix integration is moved to an external Synapse instance hosted
      on Intel-based hardware (as defined in TECHNICAL_SPEC.md, Section 3).
    - Integration with the local stack will be managed via Reverse Proxy.
    - Local Raspberry Pi 5 resources are freed for other services like
      Nextcloud and Frigate.
    - Simplified maintenance of the local deployment.

Notes:
    This decision may be revisited if Conduit or its ecosystem develops
    standardized, mature management tools in the future.
