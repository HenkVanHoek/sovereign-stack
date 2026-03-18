# Contributing to Sovereign Stack

Thank you for your interest in contributing to Sovereign Stack!

## About This Project

Sovereign Stack is a self-hosted infrastructure project designed to help individuals and small communities regain digital autonomy by hosting essential services (Nextcloud, Matrix, NetBox, and more) on a Raspberry Pi 5 with full 3-2-1 backup strategy.

## Ways to Contribute

### Reporting Bugs
- Search existing issues first
- Use the issue template if available
- Include: error messages, steps to reproduce, environment details
- Be specific and detailed

### Suggesting Features
- Open an issue with the label `enhancement`
- Describe the problem you're solving
- Explain why this would benefit the project
- Be open to discussion

### Pull Requests

#### Before Submitting
1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Test your changes** on your own system first
4. **Update documentation** if needed

#### PR Requirements
- Clear, descriptive title
- Reference related issues
- Explain what changed and why
- Keep PRs focused (one feature/fix per PR)

## Code Standards

### Language Requirements
- All code comments: **English only**
- All documentation: **English only**
- Variable names and commit messages: **English only**
- Logs and error messages: **English only**

### File Headers
Every new code file must include the GPL header. See [AGENTS.md](AGENTS.md) for the full template.

### Shell Scripts (.sh)
- Follow ShellCheck best practices
- Use `set -u` at the top
- Include `#!/bin/bash` shebang
- Use meaningful variable names
- Add error handling

### Python Scripts (.py)
- Follow PEP 8 style guidelines
- Use type hints where appropriate
- Include docstrings for functions
- Handle exceptions gracefully

### Docker Compose
- Use dictionary-style `KEY: VALUE` for environment variables
- Always use double quotes for passwords/secrets
- Every service must use `${TZ}` for timezone
- Core services must have `watchtower.enable=false` label

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/sovereign-stack.git
cd sovereign-stack

# Install dependencies (for local testing)
sudo apt install shellcheck  # For bash scripts
pip install flake8 black     # For Python

# Test a script
./backup_stack.sh --dry-run  # Check if applicable
```

## Testing

### Manual Testing Checklist
- [ ] Script runs without sudo (unless required)
- [ ] Error messages are clear in English
- [ ] Logs are written correctly
- [ ] Works on a fresh install
- [ ] No hardcoded paths

### Code Quality
```bash
# Run ShellCheck on scripts
shellcheck *.sh

# Run flake8 on Python
flake8 *.py

# Check for common issues
git diff --check
```

## Commit Messages

Follow conventional commits format:
- `feat: add new feature`
- `fix: resolve bug`
- `docs: update documentation`
- `refactor: improve code structure`
- `test: add or update tests`

Example:
```
feat: add WoL support for backup targets

Add Wake-on-LAN capability to wake NAS devices
before remote backup operations. Includes retry
logic and ping verification.

Closes #42
```

## License

By contributing, you agree that your contributions will be licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) for details.

## Questions?

- Open an issue for bugs/feature requests
- Check the [README.md](README.md) for project overview
- Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues

---

**Thank you for making Sovereign Stack better!**
