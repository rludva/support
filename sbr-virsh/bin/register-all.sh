#!/bin/bash

# 1. Check if Bitwarden CLI (bw) is installed
if ! command -v bw &> /dev/null; then
    echo "Error: 'bw' (Bitwarden CLI) is not installed or not in PATH."
    exit 1
fi

# 2. Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it (e.g., sudo dnf install jq)."
    exit 1
fi

# Load and decode RHSM credentials from Bitwarden using the Bitwarden CLI (bw)!
BW_ITEM_JSON=$(bw get item "RHSM Credentials")

# Extract ORGANIZATION_ID, ACTIVATION_KEY, and DOMAIN from the JSON output..
ORGANIZATION_ID=$(echo "$BW_ITEM_JSON" | jq -r '.fields[] | select(.name=="ORGANIZATION_ID").value')
ACTIVATION_KEY=$(echo "$BW_ITEM_JSON" | jq -r '.fields[] | select(.name=="ACTIVATION_KEY").value')
DOMAIN=$(echo "$BW_ITEM_JSON" | jq -r '.fields[] | select(.name=="DOMAIN").value')

# Get the list of RUNNING VMs from virsh (domain names)
VMS=$(sudo virsh list --state-running --name)

if [ -z "$VMS" ]; then
    echo "No running virtual machines found."
    exit 1
fi

for VM in $VMS; do
    # Construct FQDN for SSH
    TARGET="${VM}"

    echo "=================================================="
    echo "Fixing RHSM on virtual machine: $TARGET"
    echo "=================================================="

    # Connect via SSH and execute commands inside the VM
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@"$TARGET" <<EOF
        echo "[1/3] Cleaning up old identity..."
        subscription-manager clean
        rm -rf /etc/pki/consumer/*

        echo "[2/3] Registering new profile..."
        subscription-manager register --org="${ORGANIZATION_ID}" --activationkey="${ACTIVATION_KEY}"

        echo "[3/3] Result..."
        subscription-manager status | grep "Overall Status"
EOF

    # Error handling for unreachable machines
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to connect or execute commands on $TARGET."
    else
        echo "✅ DONE for $TARGET."
    fi
    echo ""
done
