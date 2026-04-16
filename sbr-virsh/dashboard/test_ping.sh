#!/bin/bash

# Determine the absolute path to the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if the core library exists before attempting to source it
if [[ -f "${SCRIPT_DIR}/vms.sh" ]]; then
    source "${SCRIPT_DIR}/vms.sh"
else
    # Define colors locally just for this fallback error message
    RED='\033[1;31m'
    NC='\033[0m'
    echo -e "${RED}[ERROR]${NC} Function vms not found in ${SCRIPT_DIR}/vms.sh"
    exit 1
fi

# Function to test network reachability via ICMP Ping
# The function name must match the filename (without .sh)
test_ping() {
    local TARGET_HOST="$1"
    local TEST_GROUP="Network"
    local TEST_NAME="ICMP Ping reachability check"

    # Send 1 ping packet, wait max 2 seconds for reply
    if ping -c 1 -W 2 "$TARGET_HOST" >/dev/null 2>&1; then
        # Format: [Result] | [Group] | [Test] | [Target]
        # We manually pad "OK" with spaces to 5 characters to center it
        printf "[${GREEN}%s${NC}] | %-15s | %-50s | %s\n" "  OK " "$TEST_GROUP" "$TEST_NAME" "$TARGET_HOST"
    else
        # "FALSE" is naturally 5 characters long
        printf "[${RED}%s${NC}] | %-15s | %-50s | %s\n" "FALSE" "$TEST_GROUP" "$TEST_NAME" "$TARGET_HOST"
    fi
}

# Derive the function name from the script filename (e.g., test_rhsm.sh -> test_rhsm)
SCRIPT_FILENAME="$(basename "${BASH_SOURCE[0]}")"
FUNCTION_NAME="${SCRIPT_FILENAME%.sh}"

# Execute the framework function dynamically using the derived name
vms "$FUNCTION_NAME"
