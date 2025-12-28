#!/bin/bash

# Barvičky pro NASA look
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Vyhledání konfigu (stejné jako u mwol.sh)
POSSIBLE_PATHS=("$(dirname "$0")/mwol.conf" "./mwol.conf" "$HOME/.mwol.conf" "/etc/mwol.conf")
CONF_FILE=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [[ -f "$path" ]]; then CONF_FILE="$path"; break; fi
done

[[ -z "$CONF_FILE" ]] && { echo -e "${RED}Error: Config not found${RESET}"; exit 1; }
source "$CONF_FILE"

shutdown_group() {
    local group=$1
    local hosts=(${OFF_GROUPS[$group]})
    local key_path="${OFF_KEYS[$group]}"
    
    # Základní nastavení SSH (timeout 5s, batch mode aby to neviselo na dotazech)
    local ssh_opts="-o ConnectTimeout=5 -o BatchMode=yes"
    
    # Pokud je v konfigu definován klíč, přidáme ho
    if [[ -n "$key_path" ]]; then
        ssh_opts="$ssh_opts -i $key_path"
        echo -e "${CYAN}Using key:${RESET} $key_path"
    fi

    echo -e "${GREEN}Shutting down group:${RESET} ${YELLOW}$group${RESET} (${#hosts[@]} hosts)"

    for target in "${hosts[@]}"; do
        echo -e "${CYAN}Sending shutdown to:${RESET} $target"
        # Spuštění na pozadí (&), aby se nečekalo na timeouty
        ssh $ssh_opts "$target" -- "sudo init 0" 
    done
    
    wait # Počkáme, až se "vystřílí" všechny příkazy
}

# Kontrola vstupu
if [ -z "$1" ] || [[ -z "${OFF_GROUPS[$1]}" ]]; then
    echo -e "${RED}Usage:${RESET} moff [group_name]"
    echo -e "${YELLOW}Available groups:${RESET} ${!OFF_GROUPS[@]}"
    exit 1
fi

shutdown_group "$1"
echo -e "${GREEN}All shutdown commands dispatched.${RESET}"