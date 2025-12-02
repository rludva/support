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

# 3. Get the folder name from the script folder path..
FOLDER_NAME="$(basename "$SCRIPT_FOLDER")"

# Name of the VM to be created..
VM_NAME="$FOLDER_NAME"

# SSH to the VM..
ssh $USER@$VM_NAME
