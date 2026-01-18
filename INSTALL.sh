#!/bin/bash
# File: INSTALL.sh
# sovereign-stack Environment Setup v1.0
# Features: Docker version check, dependency install, and permission hardening.

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- sovereign-stack Installation Helper ---${NC}"

# 1. Check for Required Packages
# These are essential for the backup scripts, Fail2Ban, and Step-CA.
PACKAGES=("msmtp" "msmtp-mta" "iptables" "curl" "openssl" "ca-certificates")

echo "Checking system dependencies..."
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo -e "[${GREEN}OK${NC}] $pkg is already installed."
    else
        echo -e "[${RED}MISSING${NC}] $pkg is not installed."
        read -p "Would you like to install $pkg? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get update && sudo apt-get install -y "$pkg"
        fi
    fi
done

# 2. Docker Engine Check
# We prefer the official convenience script for the latest version.
if command -v docker >/dev/null 2>&1; then
    DOCKER_VER=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "[${GREEN}OK${NC}] Docker version $DOCKER_VER detected."
else
    echo -e "[${RED}MISSING${NC}] Docker is not installed."
    read -p "Install the latest Docker Engine? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -sSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}Docker installed. Please log out and back in for group changes.${NC}"
    fi
fi

# 3. Secure and Enable the Scripts
# This ensures that your backup and monitoring scripts are ready to run via Cron.
echo "Hardening script permissions..."
SCRIPTS=("backup_stack.sh" "monitor_backup.sh" "gen_cert.sh")

for script in "${SCRIPTS[@]}"; do
    if [ -f "./$script" ]; then
        chmod +x "./$script"
        echo -e "[${GREEN}FIXED${NC}] $script is now executable."
    else
        echo -e "[${RED}WARN${NC}] $script not found in current directory."
    fi
done

# 4. Final Verification
echo -e "${GREEN}--- sovereign-stack Setup Complete ---${NC}"
echo "Next steps:"
echo "1. Configure your .env file: cp .env.example .env && vi .env"
echo "2. Secure your environment variables: chmod 600 .env"
echo "3. Deploy the stack: docker compose up -d"
