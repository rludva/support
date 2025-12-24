#!/bin/bash

# --- Color Definitions ---
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INPUT_FILE="blacklist.ips"

if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: $INPUT_FILE not found.${NC}"
    exit 1
fi

echo -e "${BLUE}================================================================================${NC}"
echo -e "${CYAN}                    IP GEOLOCATION REPORT (Country & City)                    ${NC}"
echo -e "${BLUE}================================================================================${NC}"

# Table Header
printf "${YELLOW}%-18s | %-20s | %-20s${NC}\n" "IP ADDRESS" "COUNTRY" "CITY"
echo "--------------------------------------------------------------------------------"

# Process IPs
# Note: We add a small sleep to avoid hitting the 45 req/min limit of the free API
count=0
while read -r ip; do
    # Skip empty lines
    [[ -z "$ip" ]] && continue
    
    # Fetch Data
    # Fields: 16386 (country, city, status)
    DATA=$(curl -s "http://ip-api.com/json/$ip?fields=status,country,city")
    
    STATUS=$(echo $DATA | jq -r '.status')
    
    if [ "$STATUS" == "success" ]; then
        COUNTRY=$(echo $DATA | jq -r '.country')
        CITY=$(echo $DATA | jq -r '.city')
        
        printf "%-18s | %-20s | %-20s\n" "$ip" "$COUNTRY" "$CITY"
    else
        printf "%-18s | ${RED}%-20s${NC} | %-20s\n" "$ip" "Unknown" "N/A"
    fi

    # API Management: 500 IPs is a lot for a free API. 
    # We pause for 1.5 seconds every 40 requests to stay under the limit.
    ((count++))
    if (( count % 40 == 0 )); then
        echo -e "${BLUE}[Rate-limit protection: Pausing for 60s]${NC}"
        sleep 60
    fi

done < "$INPUT_FILE"

echo -e "${BLUE}================================================================================${NC}"
