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

# 3. Získá pouze název (poslední segment) adresáře
FOLDER_NAME="$(basename "$SCRIPT_FOLDER")"

# Název virtuálního stroje (VM)
VM_NAME="$FOLDER_NAME"

sudo virsh domiflist $VM_NAME
