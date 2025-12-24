#!/bin/bash
set -euo pipefail

# Define Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Check if files exist in the same folder
BLOCKLIST="$SCRIPT_DIR/blacklist.ips"
if [ ! -f "$BLOCKLIST" ]; then
  echo -e "${RED}ERROR: File $BLOCKLIST not found in the current folder.${NC}"
  exit 1
fi

# Get the directory where the block-ip.sh script is located..
BLOCK_IP_SCRIPT="$SCRIPT_DIR/block-ip.sh"
if [ ! -f "$BLOCK_IP_SCRIPT" ]; then
  echo -e "${RED}ERROR: Script $BLOCK_IP_SCRIPT not found in the current folder.${NC}"
  exit 1
fi

# Get the whitelist file path..
WHITELIST_FILE="$SCRIPT_DIR/whitelist.ips"
if [ ! -f "$WHITELIST_FILE" ]; then
  echo -e "${YELLOW}Warning:${NC} Creating missing whitelist file at $WHITELIST_FILE"
  touch "$WHITELIST_FILE"
fi

# 1️⃣ Reading whitelist into an array..
mapfile -t WHITELIST_IPS < $EHITELIST_FILE

# 2️⃣ Transfering whitelist array into an associative array for faster lookups..
declare -A WHITELIST
for ip in "${WHITELIST_IPS[@]}"; do
  [[ -n "$ip" ]] && WHITELIST["$ip"]=1
done


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

  # 3️⃣ Check against whitelist..
  if [[ ${WHITELIST[$ITEM]} ]]; then
    echo -e "${CYAN}WARNING:${NC} Whitelisted IP Address: $ITEM${NC}"
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
