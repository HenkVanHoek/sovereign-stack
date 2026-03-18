# Sovereign Stack: AI Assistant & Code Review Guidelines

This document contains the strict operational and stylistic rules for the Sovereign Stack project. When reviewing, generating, or modifying code for this project, the AI MUST adhere to all constraints listed below.

## 1. Interaction & Workflow Rules

- **Never assume the current state:** Always read the latest version of a file before generating updates or suggesting modifications.
- **No assumptions:** Do not make assumptions about missing configurations; if information is missing, ask for clarification.
- **Development Environment:** Sovereign Stack is developed in PyCharm Pro on a Windows Host and tested/deployed on a Raspberry Pi 5 with NVMe storage.
- **Linter Compliance:** All code must pass PyCharm's internal inspections before being finalized.
- **Git Workflow:** Always show the plan before making changes. Ask for confirmation before implementing.

## 2. Formatting & Syntax Rules

- **Language:** All documentation pages, markdown files, and inline code comments MUST be written in English.
- **Python Style:** The line length of Python code should not exceed 88 characters (Black compatible).
- **YAML Precision:** Always put passwords and sensitive strings in YAML files between double quotes. Use dictionary-style syntax (`KEY: "VALUE"`).

## 3. Architecture & Security Rules

- **Single Source of Truth (Versioning):** Never place hardcoded version numbers inside script headers or code execution blocks. Always refer to version.py by using the exact phrase: `Version: See version.py`.
- **Licensing:** Every executable script (.sh, .py) MUST start with the extended English GNU GPLv3 license block (see Section 5).
- **Surgical Permissions:** Avoid broad `chown -R` commands across entire volumes. Scripts must target specific UIDs:
  - UID 33: Nextcloud data
  - UID 999: MariaDB databases
  - UID 70: PostgreSQL (NetBox)
  - UID 1000: Standard user files
- **Safety Guards:** Shell scripts that run on the Linux target must:
  1. Contain a check to prevent execution as root/sudo
  2. Implement flock for anti-stacking (locking)
  3. Call `verify_env.sh` before execution

## 4. Documentation Standards

### Script Documentation
Every shell script MUST include a comprehensive header with the following sections:

```
#!/bin/bash
# File: <filename>
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - <Script Title>
# ==============================================================================
#
# DESCRIPTION:
# <Brief description of what the script does (1-2 sentences)>
#
# WHAT IT DOES:
# 1. <First major function>
# 2. <Second major function>
# 3. <Third major function>
#
# EXIT CODES: (if non-standard)
#    0 = Success
#    1 = Error
#
# DEPENDENCIES:
#    - <required package or command>
#
# CONFIGURATION:
#    See .env for:
#    - <relevant environment variables>
#
# OUTPUT:
#    - <what the script produces or logs>
#
# USAGE:
#    ./<script>.sh [parameters]
#
# SCHEDULED: (if applicable)
#    Via cron: <cron expression> <script path>
#
# ==============================================================================
# Copyright (C) 2026 Henk van Hoek
...
```

### ADR Documentation
Architecture Decision Records should be created for significant technical decisions. Place them in `docs/adr/` with naming convention `000X-description.md` where X is the next available number.

Each ADR MUST include:
- Status: Proposed/Accepted/Rejected/Deprecated
- Date: YYYY-MM-DD
- Context: The situation that requires a decision
- Decision: The chosen solution with implementation details
- Rationale: Why this approach was chosen
- Consequences: Positive and negative effects
- Related Decisions: Links to other ADRs
- References: External documentation links

## 5. The Standard GPLv3 Header Template

Every new or reviewed script MUST include this exact header:

```bash
#!/bin/bash
# File: <filename>
# Part of the sovereign-stack project.
# Version: See version.py
#
# ==============================================================================
# Sovereign Stack - <Title>
# ==============================================================================
#
# DESCRIPTION:
# <Brief description>
#
# WHAT IT DOES:
# 1. <Function>
# 2. <Function>
#
# DEPENDENCIES:
#    - <package>
#
# CONFIGURATION:
#    See .env for:
#    - <variables>
#
# USAGE:
#    ./<filename>.sh
#
# ==============================================================================
# Copyright (C) 2026 Henk van Hoek
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see https://www.gnu.org/licenses.
# ==============================================================================
```

## 6. Related Documentation

For additional guidelines, refer to:
- **AGENTS.md** - Project-specific rules for AI assistants
- **CONTRIBUTING.md** - Contribution guidelines for human contributors
- **docs/adr/** - Architecture Decision Records
- **CHANGELOG.md** - Version history and notable changes

## 7. Code Quality Checklist

Before finalizing any code change, verify:
- [ ] All comments in English
- [ ] No hardcoded version numbers
- [ ] GPL header complete and correct
- [ ] Safety guards implemented (root check, flock)
- [ ] verify_env.sh called before execution
- [ ] Error handling present
- [ ] Logging for important operations
- [ ] No unnecessary developer comments (e.g., "Fix for PyCharm")
- [ ] Documentation updated if behavior changed
