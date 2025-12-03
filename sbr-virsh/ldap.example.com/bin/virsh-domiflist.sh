#!/bin/bash

# Example of values:
# ------------------
# SCRIPT_PATH=/var/virsh/bastion.local.nutius.com/virsh-ipaddress.sh
# SCRIPT_FOLDER=/var/virsh/bastion.local.nutius.com
# FOLDER_NAME=bastion.local.nutius.com


# 1. Zjistí skutečnou, absolutní cestu ke skriptu, řeší symbolické odkazy a spuštění přes PATH
SCRIPT_PATH="$(realpath "$0")"

# 2. Získá adresář, ve kterém je skript umístěn
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"

# 3. Get the parent folder of SCRIPT_FOLDER
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"

# 4. Get only the last component (folder name)
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM to be created..
VM_NAME="$FOLDER_NAME"


echo "\$ sudo virsh domiflist $VM_NAME"
sudo virsh domiflist $VM_NAME
