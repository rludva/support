#!/bin/bash

# 
SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Path to your existing backup script
# $(dirname "$0") ensures it looks in the same folder where this script is located
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"

# Regex list of system databases to exclude from backup
# You can add others like 'phpmyadmin' or 'test' here
IGNORE_DBS="^(information_schema|performance_schema|mysql|sys)$"

# -----------------------------------------------------------------------------
# Colors for Output
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color (Reset)

# -----------------------------------------------------------------------------
# Pre-flight Checks
# -----------------------------------------------------------------------------

# Check if the backup script exists and is executable
if [ ! -x "$BACKUP_SCRIPT" ]; then
    echo -e "${RED}[ERROR] The script $BACKUP_SCRIPT was not found or is not executable.${NC}"
    echo -e "${YELLOW}Hint: Run 'chmod +x backup.sh'${NC}"
    exit 1
fi

# Check if we can connect to MySQL
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}[ERROR] MySQL command could not be found.${NC}"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------

echo -e "${CYAN}--- Starting Bulk Backup Process ---${NC}"

# Fetch list of databases
# -N: No headers (skips the word "Database")
# -e: Execute query
DATABASES=$(mysql -N -e "SHOW DATABASES")

# Check if we actually got a list
if [ -z "$DATABASES" ]; then
    echo -e "${RED}[ERROR] Could not retrieve database list or no databases found.${NC}"
    echo -e "${YELLOW}Hint: Check your ~/.my.cnf credentials.${NC}"
    exit 1
fi

for DB in $DATABASES; do
    # Filter out system databases based on the regex
    if echo "$DB" | grep -Evq "$IGNORE_DBS"; then
        
        echo -e -n "Backing up ${CYAN}${DB}${NC} ... "
        
        # Run the backup script and capture any output if needed
        # We rely on the exit code ($?) of the script
        $BACKUP_SCRIPT "$DB" > /dev/null 2>&1
        
        # Check if the backup script succeeded (Exit code 0)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[OK]${NC}"
        else
            echo -e "${RED}[FAILED]${NC}"
            # Optional: Log the failure to a file
            echo "$(date): Backup failed for $DB" >> backup_errors.log
        fi
        
    else
        # Verbose: show skipped DBs (comment out if you want silence)
        # echo -e "${YELLOW}[SKIP]${NC} System database: $DB"
        : 
    fi
done

echo -e "${CYAN}--- All tasks completed ---${NC}"