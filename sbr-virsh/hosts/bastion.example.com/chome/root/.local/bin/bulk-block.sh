#!/bin/bash

# Define Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BLOCKLIST="$SCRIPT_DIR/blacklist.txt"
BLOCK_IP_SCRIPT="$SCRIPT_DIR/block-ip.sh"

# Check if files exist in the same folder
if [ ! -f "$BLOCKLIST" ]; then
    echo -e "${RED}ERROR: File $BLOCKLIST not found in the current folder.${NC}"
    exit 1
fi

if [ ! -f "$BLOCK_IP_SCRIPT" ]; then
    echo -e "${RED}ERROR: Script $BLOCK_IP_SCRIPT not found in the current folder.${NC}"
    exit 1
fi

echo -e "${BLUE}====================================================${NC}"
echo -e "${CYAN}STARTING BULK BLOCKING PROCESS${NC}"
echo -e "${BLUE}====================================================${NC}"

# Read file line by line
while read -r line || [ -n "$line" ]; do
    # Strip whitespace
    ip=$(echo "$line" | xargs)

    # Skip if empty
    if [ -z "$ip" ]; then
        continue
    fi

    # Skip if it starts with #
    if [[ "$ip" == \#* ]]; then
        continue
    fi

    echo -e "${BLUE}Attempting to block: $ip${NC}"
    # Execute the sub-script
    /bin/bash "$BLOCK_IP_SCRIPT" "$ip"
    
    echo -e "${BLUE}----------------------------------------------------${NC}"
done < "$BLOCKLIST"

echo -e "${GREEN}COMPLETED: All addresses processed.${NC}"

# Final summary of the firewall state
echo -e "${CYAN}Final Blacklist State:${NC}"
sudo nft list set inet firewalld blacklist
