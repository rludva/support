#!/bin/bash
set -euo pipefail

# --- Color definitions for terminal output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# --- Helper logging functions ---
log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_err()  { echo -e "${RED}[ERROR]${RESET} $1" >&2; }

# --- File paths ---
KUBECONFIG_SRC="/var/lib/microshift/resources/kubeadmin/kubeconfig"
KUBECONFIG_DEST="$HOME/.kube/config"

log_info "Starting MicroShift access configuration..."

# 1. Check if the source kubeconfig exists
# Using 'sudo test' because a regular user cannot read inside /var/lib/microshift
if ! sudo test -f "$KUBECONFIG_SRC"; then
    log_err "Source file does not exist: $KUBECONFIG_SRC"
    log_warn "Make sure the MicroShift service is running (sudo systemctl status microshift)."
    log_warn "On the first boot, it may take a few minutes for this file to be generated."
    exit 1
fi

# 2. Prepare the destination directory
if [ ! -d "$HOME/.kube" ]; then
    log_info "Creating directory $HOME/.kube/ ..."
    mkdir -p "$HOME/.kube/"
fi

# 3. Copy the kubeconfig
log_info "Copying kubeconfig to $KUBECONFIG_DEST ..."
# 'sudo cat' reads the file as root, redirection (>) writes it as your regular user
sudo cat "$KUBECONFIG_SRC" > "$KUBECONFIG_DEST"

# 4. Set secure permissions
log_info "Setting secure permissions (600) on ~/.kube/config ..."
chmod 600 "$KUBECONFIG_DEST"

# 5. Check if the 'oc' CLI tool is installed
if ! command -v oc &> /dev/null; then
    log_warn "The 'oc' tool was not found in the system. Skipping test commands."
    log_info "The kubeconfig is successfully prepared anyway!"
    exit 0
fi

# 6. Test the connection
log_info "Testing connection to the cluster..."

echo -e "\n${YELLOW}=== oc get nodes ===${RESET}"
oc get nodes

echo -e "\n${YELLOW}=== oc get pods -A ===${RESET}"
oc get pods -A

echo ""
log_info "Everything is successfully set up and ready to use!"