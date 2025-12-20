#!/bin/bash

# Define Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# File where unique attacker IPs are stored
BLOCKLIST="$SCRIPT_DIR/blacklist.txt"
touch "$BLOCKLIST"

# Get the directory where this script is located
BLOCK_IP_SCRIPT="$SCRIPT_DIR/block-ip.sh"
if [ ! -f "$BLOCK_IP_SCRIPT" ]; then
    echo -e "${RED}ERROR: Script $BLOCK_IP_SCRIPT not found in the current folder.${NC}"
    exit 1
fi


echo -e "${CYAN}Analyzing SSH logs for attack patterns...${NC}"

# Expanded regex to catch:
# 1. Received disconnect / Disconnected from
# 2. Invalid user ... from
# 3. Connection closed/reset by
# 4. Timeout / drop connection
IPS=$(journalctl -u sshd --since "-100days" | \
      grep -Ei "disconnect|invalid|failed|closed|reset|timeout|drop connection" | \
      grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | \
      sort -u)

# Counter for new findings
NEW_COUNT=0

for ITEM in $IPS; do
    # Only process if the IP is not already in the file
    if ! grep -qxF "$ITEM" "$BLOCKLIST"; then
        echo -e "${YELLOW}New attacker detected: ${NC}$ITEM"
        echo "$ITEM" >> "$BLOCKLIST"
        ((NEW_COUNT++))

       # Execute the sub-script and add it also to the blocklist ipset..
       /bin/bash "$BLOCK_IP_SCRIPT" "$ITEM"
    fi
done

echo -e "${GREEN}Scan complete. Found $NEW_COUNT new unique IP(s).${NC}"