#!/bin/bash

# Example of values:
# ------------------
# SCRIPT_PATH=/var/virsh/bastion.local.nutius.com/virsh-ipaddress.sh
# SCRIPT_FOLDER=/var/virsh/bastion.local.nutius.com
# FOLDER_NAME=bastion.local.nutius.com


# 1. Find the actual absolute path to the script, resolving symbolic links and execution via PATH
SCRIPT_PATH="$(realpath "$0")"

# 2. Get the directory where the script is located
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"

# 3. Get only the name (last segment) of the directory
FOLDER_NAME="$(basename "$SCRIPT_FOLDER")"

# Virtual Machine (VM) name
VM_NAME="$FOLDER_NAME"

# bastion is simply named bastion in libvirt temporarily
# and it will stay that way until I get around 
# to fixing it...
VM_NAME="$FOLDER_NAME"
VM_NAME="bastion"

echo "Searching for IP address for VM: $VM_NAME (Network: br0)"

# 1. Obtain the MAC address using virsh
# We use awk to select the fifth column (MAC) from the virsh output
# and filter by vnet0, which is located on bridge br0.
MAC=$(sudo virsh domiflist $VM_NAME | grep 'vnet0' | awk '{print $5}')

if [ -z "$MAC" ]; then
    echo "ERROR: Could not find MAC address for VM '$VM_NAME' or the VM is powered off/not connected to network br0." >&2
    exit 1
fi

echo "Found MAC address: $MAC"

# 2. Searching for the IP address in the neighbor table (ARP/Neighbor cache)
# grep filters the line by MAC and awk selects the first column (IP address).
IP_LINE=$(ip neighbor show | grep -i $MAC)

if [ -z "$IP_LINE" ]; then
    echo "ERROR: IP address not found in neighbor table (arp cache)." >&2
    echo "Ensure the VM is generating network traffic (try a ping from the VM to the router)." >&2
    exit 1
fi

IP=$(echo $IP_LINE | awk '{print $1}')

# 3. Return the IP address
echo -e "\n---------------------------------"
echo "IP address for $VM_NAME is: $IP"
echo "---------------------------------"
