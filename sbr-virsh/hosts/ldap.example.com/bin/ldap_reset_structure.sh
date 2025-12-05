#!/bin/bash
set -euo pipefail

# Color codes..
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"

#
# Reset LDAP structure
# NOTE: This will DELETE ALL DATA in the LDAP server!
# Use with caution!
# Make sure to have a backup if needed.
# 
# $ sudo systemctl stop slapd
# $ sudo rm -rf /var/lib/ldap/*
# $ sudo rm -rf /etc/openldap/slapd.d/*
# $ sudo dnf reinstall openldap-servers -y
# $ sudo chown -R ldap:ldap /var/lib/ldap
# $ sudo chown -R ldap:ldap /etc/openldap/slapd.d
# $ sudo systemctl start slapd
#

echo "----------------------------------------------------------------"
echo "TARGET VM: $VM_NAME"
echo "ACTION:    Factory Reset OpenLDAP (Destructive!)"
echo "----------------------------------------------------------------"

# ---------------------------------------------------------
# Countdown.. (Safety Catch)
# ---------------------------------------------------------
echo -e "${YELLOW}Press Ctrl+C to cancel execution.${NC}"

for i in {5..1}; do
    # -n = do not break lines, -e = interpret \r (carriage return)
    echo -ne "Erasing all data in: ${RED}$i${NC} ... \r"
    sleep 1
done

# SSH Connection
# bash -c '...' : Wrap all commands into a single block..
ssh -t "$VM_NAME" "bash -c 'set -e; \
    CYAN=\"\\033[1;36m\"; \
    RED=\"\\033[1;31m\"; \
    GREEN=\"\\033[1;32m\"; \
    NC=\"\\033[0m\"; \
    
    echo -e \"\${CYAN}[REMOTE] Stopping slapd...\${NC}\"; \
    sudo systemctl stop slapd; \
    
    echo -e \"\${RED}[REMOTE] DELETING database and config...\${NC}\"; \
    sudo rm -rf /var/lib/ldap; \
    sudo rm -rf /etc/openldap/slapd.d; \
    
    echo -e \"\${CYAN}[REMOTE] Reinstalling packages to restore default config...\${NC}\"; \
    sudo dnf reinstall openldap-servers -y > /dev/null; \
    
    echo -e \"\${CYAN}[REMOTE] Fixing permissions...\${NC}\"; \
    sudo chown -R ldap:ldap /var/lib/ldap; \
    sudo chown -R ldap:ldap /etc/openldap/slapd.d; \
    
    echo -e \"\${CYAN}[REMOTE] Starting slapd...\${NC}\"; \
    sudo systemctl start slapd; \
    
    echo -e \"\${GREEN}[REMOTE] DONE. OpenLDAP is now fresh and empty.\${NC}\"; \
'"