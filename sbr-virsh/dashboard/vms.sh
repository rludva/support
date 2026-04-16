#!/bin/bash

# Color definitions
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color (reset formatting)

# --- CORE FUNCTIONS ---

# Function to fetch the list of VMs
# We do this inside a function so it's evaluated fresh when needed
get_vms_list() {
    sudo virsh list --all --name | grep -v '^$'
}

# Framework function to run any given test against all VMs
vms() {
    local TEST_FUNCTION="$1"

    # Check if the argument is provided
    if [[ -z "$TEST_FUNCTION" ]]; then
        echo -e "${RED}[ERROR]${NC} No test function name provided to vms()!"
        return 1
    fi

    # Check if the provided test function actually exists
    if ! declare -F "$TEST_FUNCTION" > /dev/null; then
        echo -e "${RED}[ERROR]${NC} Test function '${TEST_FUNCTION}' is not defined!"
        return 1
    fi

    local VM_LIST=$(get_vms_list)

    # Optional safeguard: Check if the VM list is empty
    if [[ -z "$VM_LIST" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} No VMs found. Skipping test '${TEST_FUNCTION}'."
        return 0
    fi

    for vm in $VM_LIST; do
        # Call the function dynamically with the VM name as an argument
        "$TEST_FUNCTION" "$vm"
    done
}
