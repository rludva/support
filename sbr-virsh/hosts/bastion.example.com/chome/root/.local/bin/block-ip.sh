#!/bin/bash
set -euo pipefail

# Define Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Check if ANY argument was passed..
if [ $# -eq 0 ]; then
    echo -e "${RED}----------------------------------------------------${NC}"
    echo -e "${RED}ERROR: No IP address provided.${NC}"
    echo -e "Usage: $0 <IP_ADDRESS>"
    echo -e "${RED}----------------------------------------------------${NC}"
    exit 1
fi

# 2. Check if the FIRST argument is an empty string..
if [ -z "$1" ]; then
    echo -e "${RED}ERROR: The provided IP address is an empty string.${NC}"
    exit 1
fi

# 3. Process the provided IP address..
BLOCK_IP="$1"
echo -e "${YELLOW}Processing block request for: ${NC}${BLOCK_IP}"

# Get the whitelist file path..
WHITELIST_FILE="$SCRIPT_DIR/whitelist.ips"
if [ ! -f "$WHITELIST_FILE" ]; then
  echo -e "${YELLOW}Warning:${NC} Creating missing whitelist file at $WHITELIST_FILE"
  touch "$WHITELIST_FILE"
fi

# 1️⃣ Reading whitelist into an array..
mapfile -t WHITELIST_IPS < $WHITELIST_FILE

# 2️⃣ Transfering whitelist array into an associative array for faster lookups..
declare -A WHITELIST
for ip in "${WHITELIST_IPS[@]}"; do
  [[ -n "$ip" ]] && WHITELIST["$ip"]=1
done

# 3️⃣ Check against whitelist..
if [[ ${WHITELIST[$BLOCK_IP]:-} ]]; then
  echo -e "${RED}ERROR:${NC} Whitelisted IP Address: $ip is not allowed to be blocked."
  exit 1
fi


# Add the BLOCK_IP address as entry into the blacklist IPset in runtime..
sudo firewall-cmd --quiet --ipset=blacklist --add-entry="$BLOCK_IP"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success: IP $BLOCK_IP added to runtime blacklist.${NC}"
else
    echo -e "${YELLOW}Note: IP $BLOCK_IP is already in the runtime blacklist list or command failed.${NC}"
fi

# Add the BLOCK_IP address as entry into the blacklist IPset in permanent config..
sudo firewall-cmd --quiet --permanent --ipset=blacklist --add-entry="$BLOCK_IP"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Success: IP $BLOCK_IP added to permanent blacklist.${NC}"
else
    echo -e "${YELLOW}Note: IP $BLOCK_IP is already in the permanent blacklist list or command failed.${NC}"
fi