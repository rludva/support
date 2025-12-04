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


# Confuration parameters..
CPU_COUNT="2"
RAM="2048"
DISK_SIZE="20"
MAC_ADDRESS="52:54:00:a1:b2:c3"
NETWORK="br0-network"
IMAGE_FILE="/var/lib/libvirt/images/iso/rhel-10.0-x86_64-dvd.iso"
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
