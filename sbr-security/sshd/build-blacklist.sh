#!/bin/bash
set -euo pipefail

# Define Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the directory where this script is located..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# File where unique attacker IPs are stored..
BLOCKLIST_FILE="$SCRIPT_DIR/blacklist.ips"
if [ ! -f "$BLOCKLIST_FILE" ]; then
  echo -e "${YELLOW}Warning:${NC} Creating missing blocklist file at $BLOCKLIST_FILE"
  touch "$BLOCKLIST_FILE"
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
mapfile -t WHITELIST_IPS < $WHITELIST_FILE

# 2️⃣ Transfering whitelist array into an associative array for faster lookups..
declare -A WHITELIST
for ip in "${WHITELIST_IPS[@]}"; do
  [[ -n "$ip" ]] && WHITELIST["$ip"]=1
done


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
  # 3️⃣ Check against whitelist..
  if [[ ${WHITELIST[$ITEM]:-} ]]; then
    echo -e "${CYAN}WARNING:${NC} Whitelisted IP Address: $ITEM${NC}"
    continue
  fi

  # Only process if the IP is not already in the file
  if ! grep -qxF "$ITEM" "$BLOCKLIST_FILE"; then
    echo -e "${YELLOW}New attacker detected: ${NC}$ITEM"
    echo "$ITEM" >> "$BLOCKLIST_FILE"
    ((NEW_COUNT++))

    # Execute the sub-script and add it also to the blacklist ipset..
    /bin/bash "$BLOCK_IP_SCRIPT" "$ITEM" || true
  fi
done

echo -e "${GREEN}Scan complete. Found $NEW_COUNT new unique IP(s).${NC}"