#!/bin/bash

# Define Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Time range to analyze
SINCE="-1000days"

echo -e "Analyzing SSH logs for targeted usernames (last ${SINCE})..."
echo "----------------------------------------------------------------------"
printf "%-10s %-20s\n" "ATTEMPTS" "USERNAME"
echo "----------------------------------------------------------------------"

# 1. Fetch logs
# 2. Filter for "invalid user" (case insensitive)
# 3. Use sed to capture the word immediately following "user"
# 4. Count and sort
USERS=$(journalctl -u sshd --since "$SINCE" | \
        grep -Ei "invalid user" | \
        sed -E 's/.*[Ii]nvalid user ([^ ]+).*/\1/' | \
        sort | uniq -c | sort -nr)

if [ -z "$USERS" ]; then
    echo -e "${YELLOW}No invalid usernames found in the specified time range.${NC}"
else
    while read -r COUNT USERNAME; do
        printf "%-10s %-20s\n" "$COUNT" "$USERNAME"
    done <<< "$USERS"
fi

echo "----------------------------------------------------------------------"
