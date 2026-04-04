#!/bin/bash
set -euo pipefail

# --- Color definitions for terminal output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# --- Helper logging functions ---
log_info() { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_err()  { echo -e "${RED}[ERROR]${RESET} $1" >&2; }

log_info "Checking MicroShift and CRI-O status..."

# 1. Check if systemctl is available
if ! command -v systemctl &> /dev/null; then
    log_err "'systemctl' is not installed. This script requires a systemd-based OS."
    exit 1
fi

# 2. Check MicroShift Service Status
echo -e "\n${CYAN}======================================================================${RESET}"
echo -e "${YELLOW}=== 1/3: systemctl status microshift ===${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
# Using '--no-pager -l' to avoid getting stuck in 'less' and to show full lines.
# Using '|| true' because 'systemctl status' returns a non-zero exit code if the service is stopped,
# which would otherwise instantly kill the script due to 'set -e'.
sudo systemctl status microshift --no-pager -l || true

# 3. Check Kubepods Slice Status
echo -e "\n${CYAN}======================================================================${RESET}"
echo -e "${YELLOW}=== 2/3: systemctl status kubepods.slice ===${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
sudo systemctl status kubepods.slice --no-pager -l || true

# 4. Check Container Status via crictl
echo -e "\n${CYAN}======================================================================${RESET}"
echo -e "${YELLOW}=== 3/3: crictl ps -a ===${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
if command -v crictl &> /dev/null; then
    # Executes crictl, won't fail the script if it throws a warning
    sudo crictl ps -a || true
else
    log_warn "The 'crictl' tool is not installed or not in PATH."
    log_warn "If you are using a different container runtime, you might need 'nerdctl' or 'podman'."
fi

echo -e "\n${GREEN}=== Status check completed! ===${RESET}"