# Sovereign Stack: AI Assistant & Code Review Guidelines

This document contains the strict operational and stylistic rules for the Sovereign Stack project. When reviewing, generating, or modifying code for this project, the AI MUST adhere to all constraints listed below.

## 1. Interaction & Workflow Rules
* **Never assume the current state:** Always ask the user to provide the latest version of a file before generating updates or suggesting modifications.
* **No assumptions:** Do not make assumptions about missing configurations; if information is missing, ask for clarification.
* **Development Environment:** Sovereign Stack is developed in PyCharm Pro on a Windows Host and tested/deployed on a Linux VM.
* **Linter Compliance:** All code must pass PyCharm's internal inspections (Green Checkmark) before being finalized.

## 2. Formatting & Syntax Rules
* **No Markdown Backticks:** Never use triple backticks for code blocks or markdown files. Always indent the entire code block (including the first and last line) with 4 spaces so the parser renders it as a single raw text block.
* **Plain Text URLs:** Never format URLs as Markdown links inside code blocks, documentation, or environment variables. Always provide them as plain text strings.
* **Language:** All documentation pages, markdown files, and inline code comments MUST be written in English.
* **Python Style:** The line length of Python code should not exceed 88 characters (Black compatible).
* **YAML Precision:** Always put passwords and sensitive strings in YAML files between double quotes. Use dictionary-style syntax (KEY: "VALUE").

## 3. Architecture & Security Rules
* **Single Source of Truth (Versioning):** Never place hardcoded version numbers inside script headers or code execution blocks. Always refer to version.py by using the exact phrase: Version: See version.py.
* **Licensing:** Every executable script (.sh, .py) MUST start with the extended English GNU GPLv3 license block.
* **Surgical Permissions:** Avoid broad chown -R commands across entire volumes. Scripts must target specific UIDs (e.g., 33 for Nextcloud, 999 for databases, 70 for Netbox-db, 1000 for standard users).
* **Safety Guards:** Shell scripts that run on the Linux target must:
    1. Contain a check to prevent execution as root/sudo.
    2. Implement flock for anti-stacking (locking).
    3. Call verify_env.sh before execution.

## 4. The Standard GPLv3 Header Template
The AI must insert this exact header at the top of any generated or reviewed script:

# File: [filename]
# Part of the sovereign-stack project.
# Version: See version.py
#
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
# along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
