#!/bin/bash
set -euo pipefail

# --- COLOR DEFINITIONS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
MARIADB_ROOT_PASSWORD=$(base64 -d /var/passwd/containers/mariadb/MARIADB_ROOT_PASSWORD | tr -d '\n')

# Database Credentials..
DB_USER="root"
DB_PASS="$MARIADB_ROOT_PASSWORD"

# Helper function for printing messages
log_info() { echo -e "${BLUE}INFO:${NC} $1"; }
log_error() { echo -e "${RED}ERROR:${NC} $1"; }
log_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }

# Check if DB name was parsed correctly
if [ -z "$DB_NAME" ]; then
    log_error "Database name is empty or invalid."
    exit 1
fi

# Is the container running?
if ! sudo podman ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
  log_error "Container $CONTAINER_NAME is not running. Cannot proceed with restore."
  exit 1
fi

# Locate the backup file
BACKUP_FOLDER="$BASEDIR/backup"

log_info "Searching for the latest backup for database '$DB_NAME'..."
# Finds files starting with DB_NAME_backup_, sorts by time (newest first), takes top 1
BACKUP_FILE=$(ls -t "${BACKUP_FOLDER}/${DB_NAME}_backup_"*.sql 2>/dev/null | head -n1 || true)

# Validate backup file existence
if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup not found or does not exist."
    echo "       Searched in: $BACKUP_FOLDER"
    exit 1
fi

echo -e "${YELLOW}========================================================${NC}"
echo -e "RESTORING DATABASE: ${GREEN}$DB_NAME${NC}"
echo -e "FROM FILE:          ${BLUE}$BACKUP_FILE${NC}"
echo -e "CONTAINER:          ${BLUE}$CONTAINER_NAME${NC}"
echo -e "${YELLOW}========================================================${NC}"
echo -e "${RED}WARNING: Current database '$DB_NAME' will be DELETED and replaced by the backup!${NC}"
echo -n "Do you really want to continue? (yes/no): "
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Restore cancelled by user.${NC}"
    exit 0
fi

echo ""
log_info "Starting restore process..."

# Step A: Re-create empty DB
echo -n "1. Re-creating empty database structure... "
if mysql --host "127.0.0.1" --user="$DB_USER" --password="$DB_PASS" -e "DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8;" 2>/dev/null; then
    echo -e "$STATUS_OK"
else
    echo -e "$STATUS_FAIL"
    log_error "Failed to drop/create database."
    exit 1
fi

# Step B: Import SQL file
echo -n "2. Importing data from SQL file...         "
if mysql --host "127.0.0.1" --user="$DB_USER" --password="$DB_PASS" --default-character-set=utf8 "$DB_NAME" < "$BACKUP_FILE" 2>/dev/null; then
    echo -e "$STATUS_OK"
else
    echo -e "$STATUS_FAIL"
    log_error "Failed to import SQL data."
    exit 1
fi

echo ""
# Check status (redundant check but good for final summary)
log_success "Database '$DB_NAME' has been restored successfully."