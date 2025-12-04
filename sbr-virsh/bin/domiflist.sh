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


echo "\$ sudo virsh domiflist $VM_NAME"
sudo virsh domiflist $VM_NAME
