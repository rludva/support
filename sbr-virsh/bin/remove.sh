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

# Remove the registration from subscription-manager inside the VM..
echo "Execution of unregister and clean for $VM_NAME.."
ssh $USER@$VM_NAME "sudo subscription-manager unregister && sudo subscription-manager clean" || true

# Destroy and undefine the VM..
sudo virsh destroy $VM_NAME
sudo virsh undefine $VM_NAME

# Remove the storage file..
sudo rm -f /var/lib/libvirt/images/${VM_NAME}.qcow2
