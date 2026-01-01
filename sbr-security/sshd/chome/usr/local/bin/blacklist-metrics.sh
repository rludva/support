#!/bin/bash
set -euo pipefail

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Parameters ---
IP="${1:-}"
REASON="${2:-unknown}"
METRICS_FILE="/var/data/blacklist.ips.metrics"

# --- Validation ---
if [[ -z "$IP" ]]; then
    echo -e "${RED}ERROR: IP address is missing.${NC}"
    exit 1
fi

# Ensure jq and curl are installed
if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo -e "${RED}ERROR: 'jq' or 'curl' is not installed. Please install them first.${NC}"
    exit 1
fi

# Create metrics file if it doesn't exist
if [[ ! -f "$METRICS_FILE" ]]; then
    echo -e "${YELLOW}Notice:${NC} Creating missing metrics file at $METRICS_FILE"
    touch "$METRICS_FILE"
fi

# 1️⃣ Fetch data from API
# Added -m 5 (5s timeout) to prevent the script from hanging on slow connections
echo -e "${BLUE}Fetching GeoIP data for: ${CYAN}$IP${NC}"
DATA=$(curl -s -m 5 "http://ip-api.com/json/$IP?fields=status,country,city") || DATA='{"status":"fail"}'

# 2️⃣ Process JSON data using jq
STATUS=$(echo "$DATA" | jq -r '.status // "fail"')

if [ "$STATUS" == "success" ]; then
    COUNTRY=$(echo "$DATA" | jq -r '.country // "Unknown"')
    CITY=$(echo "$DATA" | jq -r '.city // "N/A"')
    echo -e "${GREEN}Success:${NC} Location found: $CITY, $COUNTRY"
else
    COUNTRY="Unknown"
    CITY="N/A"
    echo -e "${YELLOW}Warning:${NC} Could not retrieve location for $IP"
fi

# 3️⃣ Formatting the record for the log..
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 4️⃣ Calculate widths considering multi-byte characters..
# ${#VAR} in Bash returns the number of characters, 'wc -c' returns the number of bytes
CHAR_COUNT_COUNTRY=${#COUNTRY}
BYTE_COUNT_COUNTRY=$(echo -n "$COUNTRY" | wc -c)
DIFF_COUNTRY=$(( BYTE_COUNT_COUNTRY - CHAR_COUNT_COUNTRY ))
WIDTH_COUNTRY=$(( 30 + DIFF_COUNTRY ))

CHAR_COUNT_CITY=${#CITY}
BYTE_COUNT_CITY=$(echo -n "$CITY" | wc -c)
DIFF_CITY=$(( BYTE_COUNT_CITY - CHAR_COUNT_CITY ))
WIDTH_CITY=$(( 30 + DIFF_CITY ))

# 5️⃣ Log the event..
# Using fixed-width columns for better readability in the log file
# Format: Timestamp | IP | Country | City | Reason
printf "%-19s | %-15s | %-${WIDTH_COUNTRY}s | %-${WIDTH_CITY}s | %s\n" \
    "$TIMESTAMP" "$IP" "$COUNTRY" "$CITY" "$REASON" >> "$METRICS_FILE"

# Python Alternative:
# python3 -c "print(f'{$TIMESTAMP:<19} | {$IP:<15} | {$COUNTRY:<30} | {$CITY:<30} | {$REASON}')" >> "$METRICS_FILE"

# Original bash printf without multi-byte handling:
# printf "%-19s | %-15s | %-30s | %-30s | %s\n" "$TIMESTAMP" "$IP" "$COUNTRY" "$CITY" "$REASON" >> "$METRICS_FILE"

echo -e "${BLUE}Event logged to: ${NC}$METRICS_FILE"
