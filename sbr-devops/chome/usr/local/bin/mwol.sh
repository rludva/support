#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'


# Define potential configuration paths in order of priority..
POSSIBLE_PATHS=(
    "$(dirname "$0")/mwol.conf"
    "$HOME/.mwol.conf"
    "/etc/mwol.conf"
)

# Find the first existing config file..
CONF_FILE=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        CONF_FILE="$path"
        break
    fi
done

# Check if any config was found..
if [[ -z "$CONF_FILE" ]]; then
    echo -e "${RED}Error:${RESET} Configuration file not found."
    echo -e "${YELLOW}Tried paths:${RESET}"
    printf " - %s\n" "${POSSIBLE_PATHS[@]}"
    exit 1
fi


# Default Delay..
DEFAULT_BCAST_ADDR="192.168.0.255"
DEFAULT_IFACE="eth0"
DEFAULT_DELAY=1


# Check if config file exists..
if [ ! -f "$CONF_FILE" ]; then
    echo -e "${RED}Error:${RESET} Configuration file '$CONF_FILE' not found."
    exit 1
fi

# Print which config file is being used..
echo -e "${CYAN}Using configuration file:${RESET} $CONF_FILE"

# Load the configuration..
source "$CONF_FILE"

# Set delay and interface..
BCAST_ADDR=${BCAST_ADDRACE:-$DEFAULT_BCAST_ADDR}
IFACE=${IFACE:-$DEFAULT_IFACE}
DELAY=${DELAY:-$DEFAULT_DELAY}

# Function to send Magic Packet via UDP (VM-friendly)..
send_wol() {
    local mac=$1
    # Use Python to send the UDP broadcast
    python3 -c "
import socket
mac = '$mac'.replace(':', '')
data = bytes.fromhex('ff' * 6 + mac * 16)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
sock.sendto(data, ('$BCAST_ADDR', 9))
"
}

# Function for sequential wake..
wake_group() {
    local group_name=$1
    # Convert string from associative array into an actual array
    local mac_list=(${HOST_GROUPS[$group_name]})

    echo -e "${GREEN}Starting sequence for group:${RESET} ${YELLOW}$group_name${RESET}"
    echo -e "${CYAN}Delay set to:${RESET} ${DELAY}s"
    
    for mac in "${mac_list[@]}"; do
        echo -e "${CYAN}Waking up:${RESET} $mac"
        send_wol "$mac"
        #sudo ether-wake -i "$IFACE" "$mac"
        #echo ">>> WOL sent to $mac (simulated)"
        sleep "$DELAY"
    done
}

# Check input..
if [ -z "$1" ]; then
    echo -e "${RED}Usage:${RESET} mwol [group_name]"
    echo -e "${YELLOW}Available groups:${RESET} ${!HOST_GROUPS[@]}"
    exit 1
fi

if [[ -n "${HOST_GROUPS[$1]}" ]]; then
  wake_group "$1"
  echo -e "${GREEN}Done.${RESET}"
  exit 0
fi

echo -e "${RED}Error: Group '$1' not found in config.${RESET}"
echo -e "${YELLOW}Available groups:${RESET} ${!HOST_GROUPS[@]}"
exit 1
