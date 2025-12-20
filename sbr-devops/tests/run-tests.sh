#!/bin/bash

# --- Color definitions ---
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- Column width definitions ---
W_STAT=10
W_FILE=40
W_DESC=70

PASSED=0
FAILED=0
TOTAL=0

# Function to print a divider line
print_line() {
    printf "${BLUE}%$((W_STAT + W_FILE + W_DESC + 6))s${NC}\n" | tr ' ' '-'
}

echo -e "${BLUE}${BOLD}==========================================================================================${NC}"
echo -e "${BLUE}${BOLD}                           RHEL 10 INFRASTRUCTURE UNIT TESTS                              ${NC}"
echo -e "${BLUE}${BOLD}==========================================================================================${NC}"

# Header
printf "${BOLD}%-${W_STAT}s | %-${W_FILE}s | %-${W_DESC}s${NC}\n" "STATUS" "FILE NAME" "TEST DESCRIPTION"
print_line

# --- ZMĚNA: Hledání souborů test-*.sh v aktuálním adresáři ---
TEST_FILES=$(ls test-*.sh 2>/dev/null)

if [ -z "$TEST_FILES" ]; then
    echo -e "${RED}No test scripts found (pattern: test-*.sh).${NC}"
    exit 1
fi

for script in $TEST_FILES; do
    # Přeskočíme samotný test-run.sh, pokud by se náhodou jmenoval podobně
    [ "$script" == "test-run.sh" ] && continue

    ((TOTAL++))

    # Extraction of description from the script file
    DESC=$(grep "# DESCRIPTION:" "$script" | head -1 | sed 's/# DESCRIPTION: //')
    [ -z "$DESC" ] && DESC="No description provided"

    # Execution of the test
    bash "./$script" &>/dev/null
    EXIT_CODE=$?

    # Status determination
    if [ $EXIT_CODE -eq 0 ]; then
        COLOR=$GREEN
        RES_TEXT="[  OK  ]"
        ((PASSED++))
    else
        COLOR=$RED
        RES_TEXT="[ FAIL ]"
        ((FAILED++))
    fi

    # Print the result row
    printf "${COLOR}${BOLD}%-${W_STAT}b${NC} | " "$RES_TEXT"
    printf "%-${W_FILE}s | %-${W_DESC}s\n" "$script" "$DESC"
done

print_line
echo -e "${BOLD}SUMMARY:${NC}"
echo -e "  Total Executed: $TOTAL"
echo -e "  Success:        ${GREEN}$PASSED${NC}"
echo -e "  Failures:       ${RED}$FAILED${NC}"
echo -e "${BLUE}${BOLD}==========================================================================================${NC}"

# Exit with error if any test failed
[ $FAILED -gt 0 ] && exit 1 || exit 0