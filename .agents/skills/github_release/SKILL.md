---
name: github-release
description: Guidelines for staging, committing, tagging, and pushing releases of the Sovereign Stack to GitHub. Activate this skill when the user requests to push changes, release a new version, or synchronize code with GitHub.
---

# GitHub Release & Push Skill

This skill outlines the standard workflow for committing changes, tagging releases, and pushing code for the Sovereign Stack.

## 1. Release Flow Checklist

To perform a clean release, follow these steps in order:

### Step 1: Verify Version & Single Source of Truth
- Open `version.py` and inspect the version number.
- **IMPORTANT**: The version number must only be incremented manually by the owner. The AI assistant should not modify `version.py` unless explicitly directed.
- Confirm the version in `version.py` matches the intended release tag.

### Step 2: Check Git Status
- Run `git status` to ensure all modified and untracked files are accounted for.
- Confirm that new files have the correct GPL licensing header as specified in `AGENTS.md`.

### Step 3: Stage and Commit Changes
- Commit messages must be written in **English only**.
- Format the commit message clearly, summarizing the key features, improvements, or fixes.
- Stage the files (`git add .` or stage specific files) and commit:
  ```bash
  git commit -m "feat/fix: descriptive English message"
  ```

### Step 4: Tag the Release
- Create an annotated Git tag locally using the version from `version.py`:
  ```bash
  git tag -a "v<VERSION>" -m "Release v<VERSION> - <Brief Description>"
  ```
  *(Example: `git tag -a "v4.5.0" -m "Release v4.5.0 - Nextcloud App Auto-Updates"`)*

### Step 5: Push to GitHub
- Push both the commits and the tags to the remote repository:
  ```bash
  git push origin main --tags
  ```

---

## 2. Troubleshooting & Best Practices

- **Tag Inconsistency**: If a tag already exists on GitHub, do not overwrite it. If you need to fix a release, coordinate with the user to increment the patch version in `version.py` instead.
- **Line Endings**: Be mindful of CRLF vs. LF line endings when working between Windows and Linux. The repository uses standard `.gitattributes` or `.editorconfig` to enforce proper line endings.
