#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Script: ldap_restore.sh
# Purpose: Restore OpenLDAP from a local backup to a remote server.
# Warning: THIS IS DESTRUCTIVE. It wipes existing data before restoring.
# Usage:   ./bin/ldap_restore.sh <timestamp>
# -----------------------------------------------------------------------------

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"

BACKUP_TIMESTAMP="$1" 

# Validation: Check if timestamp argument is provided
if [ -z "$BACKUP_TIMESTAMP" ]; then
    echo "Usage: $0 <vm_name> <timestamp_folder_name>"
    echo ""
    echo "Available backups for $VM_NAME:"
    # List available backup folders
    ls -1 "${BASEDIR}/backups/${VM_NAME}" 2>/dev/null || echo "No backups found."
    exit 1
fi

BACKUP_SRC="${BASEDIR}/backups/${VM_NAME}/${BACKUP_TIMESTAMP}"
CONFIG_LDIF="${BACKUP_SRC}/config.ldif"
DATA_LDIF="${BACKUP_SRC}/data.ldif"

# Validation: Check if backup files exist
if [ ! -f "$CONFIG_LDIF" ] || [ ! -f "$DATA_LDIF" ]; then
    echo "ERROR: Backup files missing in $BACKUP_SRC"
    echo "Expected: config.ldif and data.ldif"
    exit 1
fi

# ANSI Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

echo "----------------------------------------------------------------"
echo "TARGET VM: $VM_NAME"
echo "ACTION:    REMOTE RESTORE from: $BACKUP_TIMESTAMP"
echo -e "${RED}WARNING: This will DELETE ALL CURRENT DATA on the server!${NC}"
echo "----------------------------------------------------------------"

read -p "Are you sure? Press Enter to continue or Ctrl+C to abort..."

# 1. Upload backup files to remote /tmp
echo -e "${CYAN}[LOCAL] Uploading backup to /tmp on server...${NC}"
scp -q "$CONFIG_LDIF" "${VM_NAME}:/tmp/restore_config.ldif"
scp -q "$DATA_LDIF" "${VM_NAME}:/tmp/restore_data.ldif"

# 2. Execute Restore Logic on Remote Server
ssh -t "$VM_NAME" "bash -c 'set -e; \
    CYAN=\"\\033[1;36m\"; NC=\"\\033[0m\"; \
    \
    echo -e \"\${CYAN}[REMOTE] Stopping slapd service...\${NC}\"; \
    sudo systemctl stop slapd; \
    \
    echo -e \"\${CYAN}[REMOTE] Wiping /var/lib/ldap & /etc/openldap/slapd.d... \${NC}\"; \
    sudo rm -rf /var/lib/ldap/*; \
    sudo rm -rf /etc/openldap/slapd.d/*; \
    \
    echo -e \"\${CYAN}[REMOTE] Restoring CONFIGURATION (cn=config)...\${NC}\"; \
    # -n 0 = Config Database, -F = Configuration Directory
    sudo slapadd -n 0 -F /etc/openldap/slapd.d -l /tmp/restore_config.ldif; \
    \
    echo -e \"\${CYAN}[REMOTE] Restoring DATA (Main Database)...\${NC}\"; \
    # -n 2 = MDB Database
    sudo slapadd -n 2 -F /etc/openldap/slapd.d -l /tmp/restore_data.ldif; \
    \
    echo -e \"\${CYAN}[REMOTE] Fixing ownership and permissions...\${NC}\"; \
    sudo chown -R ldap:ldap /etc/openldap/slapd.d; \
    sudo chown -R ldap:ldap /var/lib/ldap; \
    \
    echo -e \"\${CYAN}[REMOTE] Cleaning up temporary files...\${NC}\"; \
    sudo rm -f /tmp/restore_config.ldif /tmp/restore_data.ldif; \
    \
    echo -e \"\${CYAN}[REMOTE] Starting slapd service...\${NC}\"; \
    sudo systemctl start slapd; \
    \
    echo -e \"\${GREEN}[REMOTE] RESTORE COMPLETE.${NC}\"; \
'"