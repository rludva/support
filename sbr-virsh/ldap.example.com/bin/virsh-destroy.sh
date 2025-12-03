#!/bin/bash

# Example of values:
# ------------------
# SCRIPT_PATH=/var/virsh/bastion.local.nutius.com/virsh-ipaddress.sh
# SCRIPT_FOLDER=/var/virsh/bastion.local.nutius.com
# FOLDER_NAME=bastion.local.nutius.com


# 1. Get the full path of the script..
SCRIPT_PATH="$(realpath "$0")"

# 2. Get the folder path from the script path..
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"

# 3. Get the parent folder of SCRIPT_FOLDER
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"

# 4. Get only the last component (folder name)
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM to be created..
VM_NAME="$FOLDER_NAME"

# Remove the registration from subscription-manager inside the VM..
echo "Execution of unregister and clean for $VM_NME.."
ssh $USER@$VM_NAME "sudo subscription-manager unregister && sudo subscription-manager clean"

# Make it possible to break the script..
source $SCRIPT_FOLDER/wait.sh

# Destroy and undefine the VM..
sudo virsh destroy $VM_NAME
sudo virsh undefine $VM_NAME

# Remove the storage file..
sudo rm -f /var/lib/libvirt/images/${VM_NAME}.qcow2
