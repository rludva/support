#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Script: ldap_backup.sh
# Purpose: Back up OpenLDAP Configuration and Data from a remote server.
# Usage:   ./bin/ldap_backup.sh
# -----------------------------------------------------------------------------

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${BASEDIR}/backups/${VM_NAME}/${TIMESTAMP}"

# ANSI Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo "----------------------------------------------------------------"
echo "TARGET VM: $VM_NAME"
echo "ACTION:    REMOTE Backup (Config + Data)"
echo "----------------------------------------------------------------"

# 1. Create local backup directory
mkdir -p "$BACKUP_DIR"

# 2. Export data on the remote server (to /tmp)
# We use -t to allow sudo password entry if required.
echo -e "${CYAN}[REMOTE] Generating dump files in /tmp...${NC}"
ssh -t "$VM_NAME" "bash -c 'set -e; \
    echo \"Exporting CONFIG database (cn=config)...\"; \
    sudo slapcat -n 0 -l /tmp/backup_config.ldif; \
    \
    echo \"Exporting MAIN database (Data)...\"; \
    sudo slapcat -n 2 -l /tmp/backup_data.ldif; \
    \
    echo \"Adjusting permissions for download...\"; \
    sudo chmod 644 /tmp/backup_*.ldif; \
'"

# 3. Download files to local machine
echo -e "${CYAN}[LOCAL] Downloading files via SCP...${NC}"
scp -q "${VM_NAME}:/tmp/backup_config.ldif" "${BACKUP_DIR}/config.ldif"
scp -q "${VM_NAME}:/tmp/backup_data.ldif" "${BACKUP_DIR}/data.ldif"

# 4. Cleanup on remote server
echo -e "${CYAN}[REMOTE] Cleaning up temporary files...${NC}"
ssh -t "$VM_NAME" "sudo rm -f /tmp/backup_config.ldif /tmp/backup_data.ldif"

# 5. Summary
if [ -f "${BACKUP_DIR}/config.ldif" ] && [ -f "${BACKUP_DIR}/data.ldif" ]; then
    echo -e "${GREEN}SUCCESS! Backup saved to:${NC}"
    echo "$BACKUP_DIR"
else
    echo -e "${RED}ERROR: Backup failed. Files are missing.${NC}"
    exit 1
fi