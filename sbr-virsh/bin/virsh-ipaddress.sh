#!/bin/bash
set -euo pipefail

#
VM_NAME="${1:?Usage: $0 <hostname>}"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
HOSTDIR="$BASEDIR/hosts/$VM_NAME"
RESOURCES_DIR="$HOSTDIR"

if [[ ! -d "$HOSTDIR" ]]; then
    echo "Host directory not found: $HOSTDIR"
    exit 1
fi


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
