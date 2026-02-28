#!/bin/bash
set -euo pipefail

# --- COLOR DEFINITIONS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Status indicators
STATUS_OK="${GREEN}[ OK ]${NC}"
STATUS_FAIL="${RED}[ FAILED ]${NC}"

# Get database name from command line argument..
DB_NAME="${1:?Usage: $0 <database_name>}"

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the container..
CONTAINER_NAME="$FOLDER_NAME"

# Set MariaDB backup parameters..
MARIADB_ROOT_PASSWORD=$(base64 -d /var/containers/mariadb/.MARIADB_ROOT_PASSWORD | tr -d '\n')
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Database Credentials..
DB_USER="root"
DB_PASS="$MARIADB_ROOT_PASSWORD"

# Helper function for printing messages
log_info() { echo -e "${BLUE}INFO:${NC} $1"; }
log_error() { echo -e "${RED}ERROR:${NC} $1"; }
log_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }

# Is the container running?
if ! sudo podman ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
  log_error "Container $CONTAINER_NAME is not running. Backup aborted."
  exit 1
fi

# Build the backup file path..
BACKUP_FOLDER="$BASEDIR/backup"
# Ensure backup directory exists
mkdir -p "$BACKUP_FOLDER"
BACKUP_FILE="${BACKUP_FOLDER}/${DB_NAME}_backup_${TIMESTAMP}.sql"

# --- VISUAL HEADER ---
echo -e "${YELLOW}========================================================${NC}"
echo -e "BACKING UP DATABASE: ${GREEN}$DB_NAME${NC}"
echo -e "CONTAINER:           ${BLUE}$CONTAINER_NAME${NC}"
echo -e "DESTINATION:         ${BLUE}$BACKUP_FILE${NC}"
echo -e "${YELLOW}========================================================${NC}"

# Execute the backup command..
echo -n "Exporting data to SQL file... "

# We use 'if' to capture the exit code gracefully for the visual indicator
if mysqldump \
  --host "127.0.0.1" \
  --user="$DB_USER" \
  --password="$DB_PASS" \
  --default-character-set=utf8 \
  --extended-insert=FALSE \
  "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then

  echo -e "$STATUS_OK"
  echo ""
  log_success "Backup completed successfully."
  
  # Optional: Show file size
  FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo -e "       Backup Size: ${YELLOW}$FILE_SIZE${NC}"

else
  echo -e "$STATUS_FAIL"
  echo ""
  log_error "Backup failed."
  
  # Clean up the empty/partial file if backup failed
  if [ -f "$BACKUP_FILE" ]; then
    rm "$BACKUP_FILE"
    echo "       (Partial backup file removed)"
  fi
  exit 1
fi