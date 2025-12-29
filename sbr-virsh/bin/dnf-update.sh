#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color (Reset)

# Get the absolute path of the script's directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Path to the hosts directory (one level up from bin)
HOSTS_DIR="$SCRIPT_DIR/../hosts"

# Check if the hosts directory exists
if [ ! -d "$HOSTS_DIR" ]; then
    echo -e "${RED}Error: Directory $HOSTS_DIR not found.${NC}"
    exit 1
fi

echo -e "${BLUE}=== Starting bulk DNF update ===${NC}"

# Iterate through all subdirectories in hosts/
# Use nullglob to handle empty directories gracefully
shopt -s nullglob
for vm_path in "$HOSTS_DIR"/*/; do
 
    # Strip trailing slash and get the folder name
    vm_name=$(basename "$vm_path")
    
    echo -e "${YELLOW}[VM: $vm_name]${NC} Checking status..."

    # 1. Check VM state via virsh
    # Redirect stderr to /dev/null to hide errors if VM doesn't exist in virsh
    vm_state=$(sudo virsh domstate "$vm_name" 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo -e "  ${RED}[!] VM '$vm_name' not found in virsh. Skipping.${NC}"
        continue
    fi

    # 2. Start the VM if it is not running
    if [ "$vm_state" != "running" ]; then
        echo -e "  [>] VM is not running (State: $vm_state). Starting..."
        sudo virsh start "$vm_name" > /dev/null
        
        # Wait for the OS to boot up and SSH to become available
        echo -e "  ${BLUE}[waiting]${NC} Giving the VM 200 seconds to boot..."
        sleep 200
    fi

    # 3. Execute update via SSH
    # -t: force pseudo-terminal (needed for sudo)
    # -o ConnectTimeout: don't hang forever if the host is down
    echo -e "  [*] Connecting via SSH to run dnf update..."
    ssh -t -o ConnectTimeout=15 "$vm_name" "sudo dnf update -y"

    # Check exit code of the SSH command
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}[OK] Update successful for '$vm_name'.${NC}"
    else
        echo -e "  ${RED}[ERROR] Update failed for '$vm_name'.${NC}"
    fi
done

echo -e "${GREEN}Batch update process finished.${NC}"