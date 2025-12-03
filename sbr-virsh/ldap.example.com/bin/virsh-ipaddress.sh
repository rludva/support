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

echo "Hledání IP adresy pro VM: $VM_NAME (Síť: br0-network)"

# 1. Získání MAC adresy pomocí virsh
# Používáme awk, abychom z výstupu virsh vybrali pátý sloupec (MAC)
# a filtrujeme podle vnet0, které se nachází na bridge br0-network.
MAC=$(sudo virsh domiflist $VM_NAME | grep 'vnet0' | awk '{print $5}')

if [ -z "$MAC" ]; then
    echo "CHYBA: Nepodařilo se najít MAC adresu pro VM '$VM_NAME' nebo je VM vypnutá/není připojena k síti br0-network." >&2
    exit 1
fi

echo "Nalezena MAC adresa: $MAC"

# 2. Hledání IP adresy v tabulce sousedů (ARP/Neighbor cache)
# grep vyfiltruje řádek podle MAC a awk vybere první sloupec (IP adresa).
IP_LINE=$(ip neighbor show | grep -i $MAC)

if [ -z "$IP_LINE" ]; then
    echo "CHYBA: IP adresa nenalezena v tabulce sousedů (arp cache)." >&2
    echo "Ujistěte se, že VM generuje síťový provoz (zkuste ping z VM na router)." >&2
    exit 1
fi

IP=$(echo $IP_LINE | awk '{print $1}')

# 3. Vrácení IP adresy
echo -e "\n---------------------------------"
echo "IP adresa pro $VM_NAME je: $IP"
echo "---------------------------------"
