#!/bin/bash
set -euo pipefail

#
VM_NAME="${1:?Usage: $0 <hostname>}"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
HOSTDIR="$BASEDIR/hosts/$VM_NAME"

if [[ ! -d "$HOSTDIR" ]]; then
    echo "Host directory not found: $HOSTDIR"
    exit 1
fi

# -----------------------------------------------------------------------------
# CONFIGURATION & DEFAULTS
# -----------------------------------------------------------------------------
# Default values (used if the specific file is missing in the host directory)
DEFAULT_CPU="2"
DEFAULT_RAM="2048"
DEFAULT_DISK_SIZE="20"
DEFAULT_NETWORK="br0-network"
DEFAULT_MAC_ADDRESS="52:54:00:12:34:56"

# Path to ISO (modify if your location differs)
IMAGE_FILE="/var/lib/libvirt/images/iso/rhel-10.0-x86_64-dvd.iso"
OS_VARIANT="rhel10.0"

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------
log_info() { echo -e "\e[32m[INFO]\e[0m $1"; }
log_err()  { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }

# Function to load a parameter: File > Default > Error (if critical)
# Usage: load_param "FILENAME" "DEFAULT_VALUE"
load_param() {
    local filename="$1"
    local default="$2"
    local filepath="$HOSTDIR/$filename"
    
    if [[ -f "$filepath" ]]; then
        # Read and trim whitespace
        local val
        val=$(cat "$filepath" | tr -d '[:space:]')
        
        if [[ -n "$val" ]]; then
            echo "$val"
            return 0
        fi
    fi
    
    # If file doesn't exist or is empty, return default
    echo "$default"
}

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

# Verify Host Directory
if [[ ! -d "$HOSTDIR" ]]; then
    log_err "Host directory does not exist: $HOSTDIR"
    exit 1
fi

log_info "Preparing configuration for VM: $VM_NAME"

# --- 1. LOAD PARAMETERS ---

# CPU
DEFAULT_CPU_FILENAME="virt-install.vcpus"
CPU_COUNT=$(load_param "$DEFAULT_CPU_FILENAME" "$DEFAULT_CPU")
# Validation: Integer check
if [[ ! "$CPU_COUNT" =~ ^[0-9]+$ ]]; then
    log_err "Invalid CPU value: '$CPU_COUNT' (integer expected)."
    exit 1
fi

# RAM
DEFAULT_RAM_FILENAME="virt-install.ram"
RAM=$(load_param "$DEFAULT_RAM_FILENAME" "$DEFAULT_RAM")
# Validation: Integer check
if [[ ! "$RAM" =~ ^[0-9]+$ ]]; then
    log_err "Invalid RAM value: '$RAM' (integer expected)."
    exit 1
fi

# DISK
DEFAULT_DISK_SIZE_FILENAME="virt-install.disk_size"
DISK_SIZE=$(load_param "disk_size" "$DEFAULT_DISK_SIZE")
# Validation: Integer check
if [[ ! "$DISK_SIZE" =~ ^[0-9]+$ ]]; then
    log_err "Invalid Disk Size value: '$DISK_SIZE' (integer expected)."
    exit 1
fi

# NETWORK
DEFAULT_NETWORK_FILENAME="virt-install.network"
NETWORK=$(load_param "$DEFAULT_NETWORK_FILENAME" "$DEFAULT_NETWORK")
# Validation: Not empty
if [[ -z "$NETWORK" ]]; then
    log_err "Network name cannot be empty."
    exit 1
fi


#
# Read MAC address from file
#
DEFAULT_MAC_ADDRESS_FILENAME="virt-install.mac_address"
MAC_ADDRESS=$(load_param "$DEFAULT_MAC_ADDRESS_FILENAME" "$DEFAULT_MAC_ADDRESS")
if [[ -z "$MAC_ADDRESS" ]]; then
    echo "Error: The MAC_ADDRESS $MAC_ADDRESS is empty."
    exit 1
fi

# 4. Validate the MAC address format..
# Regex vysvětlení:
# ^52:54:00: -> Must start with 52:54:00: prefix!
# [0-9A-Fa-f]{2}: -> Two hex digits followed by a colon (3. oktet)
# {2} -> Repeat the previous group 2 times (4. and 5. oktet)
# [0-9A-Fa-f]{2}$ -> Two hex digits at the end (6. oktet)
if [[ ! "$MAC_ADDRESS" =~ ^52:54:00(:[0-9A-Fa-f]{2}){3}$ ]]; then
    echo "Error: '$MAC_ADDRESS' not a valid MAC address."
    echo "Expected format: 52:54:00:XX:XX:XX where X is a hexadecimal digit."
    exit 1
fi

#
# End of MAC address reading
#


# Confuration other parameters..
IMAGE_FILE="/var/lib/libvirt/images/iso/rhel-10.0-x86_64-dvd.iso"
OS_VARIANT="rhel10.0"

# --- SUMMARY ---
echo "----------------------------------------"
echo "VM Name:    $VM_NAME"
echo "CPU:        $CPU_COUNT"
echo "RAM:        $RAM MB"
echo "Disk:       $DISK_SIZE GB"
echo "Network:    $NETWORK"
echo "MAC:        $MAC_ADDRESS"
echo "ISO:        $IMAGE_FILE"
echo "OS Variant: $OS_VARIANT"
echo "----------------------------------------"

# --- 5. RESOURCE CHECK ---
if [[ ! -f "$IMAGE_FILE" ]]; then
    log_err "ISO image not found: $IMAGE_FILE"
    exit 1
fi

# --- 6. EXECUTION ---
log_info "Starting virt-install..."

#
# Prepare virt-install arguments..
VIRSH_ARGS=(
  --name "$VM_NAME" \
  --ram $RAM \
  --vcpus $CPU_COUNT \
  --disk path=/var/lib/libvirt/images/${VM_NAME}.qcow2,size=$DISK_SIZE \
  --os-variant $OS_VARIANT \
  --location $IMAGE_FILE \
  --graphics none \
  --console pty,target_type=serial \
  --disk path=$IMAGE_FILE,device=cdrom,readonly=on \
  --extra-args 'console=ttyS0,115200n8 inst.text inst.repo=cdrom inst.ks=file:/anaconda-ks.cfg' \
  --initrd-inject=$HOSTDIR/anaconda-ks.cfg \
  --autostart
)

#
# If MAC address is empty, do not include it in the network argument..
NETWORK_ARG="network=$NETWORK,mac=$MAC_ADDRESS"
if [[ -z "$MAC_ADDRESS" ]] || [[ "$MAC_ADDRESS" == "52:54:00:00:00:00" ]]; then
  NETWORK_ARG="network=$NETWORK"
fi

# Add network argument..
ARGS+=(--network "$NETWORK_ARG")

#
# Process the installation..
sudo virt-install "${VIRSH_ARGS[@]}"
