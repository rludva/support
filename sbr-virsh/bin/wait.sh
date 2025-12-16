#!/bin/bash

# --- Configuration ---
# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Get wait time from the first argument, default to 10 if not provided
# syntax ${1:-10} means: Use $1, if null/unset use 10.
WAIT_TIME=${1:-10}

# Validate that the input is a positive integer
if ! [[ "$WAIT_TIME" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: The argument must be a positive integer.${RESET}"
    exit 1
fi

# Total wait time in seconds
COUNT=$WAIT_TIME

echo -e "${YELLOW}Script execution paused.${RESET}"
echo "Press any key to abort, otherwise the script continues automatically.."

# --- Countdown Loop ---
while [ $COUNT -gt 0 ]; do
    # -n: do not output the trailing newline
    # -e: enable interpretation of backslash escapes
    # \r: carriage return (moves cursor to start of line to overwrite the number)
    echo -ne "Continuing in: ${YELLOW}$COUNT${RESET} s...   \r"

    # Wait for input for 1 second
    # -r: prevents backslash escaping
    # -t 1: wait 1 second
    # -n 1: wait for exactly 1 character
    # -s: silent mode (doesn't print the character you type)
    read -r -t 1 -n 1 -s input

    # Check return code ($?). 0 means a key was pressed.
    if [ $? -eq 0 ]; then
        echo "" # New line for clean formatting
        echo -e "${RED}Manual break triggered! Exiting script.${RESET}"
        exit 1
    fi

    # Decrement the counter
    ((COUNT--))
done

# --- Final Execution ---
echo -ne "Continuing in: ${YELLOW}0${RESET} s...   \r" # visuals: show 0 at the end
echo ""
echo -e "${GREEN}Timeout reached. Resuming script execution...${RESET}"

# Place the rest of your script logic here...