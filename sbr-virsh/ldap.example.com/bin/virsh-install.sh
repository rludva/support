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

# Confuration parameters..
CPU_COUNT="2"
RAM="2048"
DISK_SIZE="20"
MAC_ADDRESS="52:54:00:b7:bc:dc"
NETWORK="br0-network"
IMAGE_FILE="/var/lib/libvirt/images/rhel-10.0-x86_64-dvd.iso"
OS_VARIANT="rhel10.0"

# Process the installation..
sudo virt-install \
  --name "$VM_NAME" \
  --ram $RAM \
  --vcpus $CPU_COUNT \
  --disk path=/var/lib/libvirt/images/${VM_NAME}.qcow2,size=$DISK_SIZE \
  --os-variant $OS_VARIANT \
  --location $IMAGE_FILE \
  --network network=$NETWORK,mac=$MAC_ADDRESS \
  --graphics none \
  --console pty,target_type=serial \
  --disk path=$IMAGE_FILE,device=cdrom,readonly=on \
  --extra-args 'console=ttyS0,115200n8 inst.text inst.repo=cdrom inst.ks=file:/anaconda-ks.cfg' \
  --initrd-inject=anaconda-ks.cfg \
  --autostart