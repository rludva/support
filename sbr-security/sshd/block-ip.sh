#!/bin/bash

# Define Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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