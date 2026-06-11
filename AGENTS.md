# Project Guidelines for AI Assistants

## Language Requirements
- **All code comments**: English only
- **All documentation (README, MD files)**: English only  
- **All logs and error messages**: English only
- **Variable names and commit messages**: English only

## Code File Header Required
Every new code file must include this header:

```python
# File: <filename>
# Part of the sovereign-stack project.
# Version: See version.py

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
```

## Docker Compose Standards
- Use dictionary-style `KEY: VALUE` for environment variables (not `KEY=VALUE`)
- Always use double quotes for passwords/secrets in YAML/JSON
- Every service must use `${TZ}` for timezone
- Core services must have `watchtower.enable=false` label

## Versioning
- Single source of truth: version.py (manual version increment by owner)
