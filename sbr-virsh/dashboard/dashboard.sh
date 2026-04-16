#!/bin/bash

# --- CONFIGURATION ---
DISPLAY_TIME_SECONDS=300

# Color definitions
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load all matching scripts into an array
SCRIPT_ARRAY=(test_*.sh)
TOTAL_SCRIPTS=${#SCRIPT_ARRAY[@]}

# Safety check if any scripts were actually found
if [[ $TOTAL_SCRIPTS -eq 0 || ! -e "${SCRIPT_ARRAY[0]}" ]]; then
    echo "No matching scripts found!"
    exit 1
fi

# Single infinite loop using an index and modulo operator
INDEX=0
while true; do
    CURRENT_SCRIPT="${SCRIPT_ARRAY[$INDEX]}"

    if [[ -x "$CURRENT_SCRIPT" ]]; then
        clear
        echo -e "${BLUE}==================================================${NC}"
        echo -e "${YELLOW} MONITORING: ${CURRENT_SCRIPT}${NC}"
        echo -e "${BLUE}==================================================${NC}"
        echo ""

        # Execute the script in the background
        ./"$CURRENT_SCRIPT" &
        SCRIPT_PID=$!

        sleep "$DISPLAY_TIME_SECONDS"

        # Check if the script is still alive and kill it if necessary
        if ps -p "$SCRIPT_PID" > /dev/null 2>&1; then
            kill "$SCRIPT_PID" 2>/dev/null
            sleep 0.5
            kill -9 "$SCRIPT_PID" 2>/dev/null
            echo -e "\n${YELLOW}[INFO] Time limit reached. Process terminated.${NC}"
        else
            echo -e "\n${BLUE}[INFO] Process completed successfully.${NC}"
        fi

        sleep 1
    fi

    # Elegant trick to loop endlessly: 
    # Increment the index, but wrap back to 0 when it reaches TOTAL_SCRIPTS
    INDEX=$(( (INDEX + 1) % TOTAL_SCRIPTS ))
done
