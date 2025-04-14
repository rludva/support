#!/bin/bash

HEADER="(header)"

# Log file
OC_MIRROR_LOG="/tmp/oc-mirror.log"

# If the log file exists, remove it...
if [ -f $OC_MIRROR_LOG ]; then
    rm $OC_MIRROR_LOG
fi

# Touch the log file..
touch $OC_MIRROR_LOG

# Check if oc-mirror is installed on the system..
if ! command -v oc-mirror &> /dev/null
then
    echo "oc-mirror could not be found. Please install it using 'npm install -g oc-mirror'"
    exit
fi

function command_text() {
    COMMAND="$1"

    # Zobrazení tučného textu
		mecho "$HEADER"
    mecho "\033[1m$COMMAND\033[0m"
}

function mecho() {
    echo -e "$1" >> $OC_MIRROR_LOG
}

function new_page() {
		reset_sequence=$(tput reset)
    echo -e "$reset_sequence" >> $OC_MIRROR_LOG
}

# Print oc-mirror version
command_text "$ oc-mirror version --output json | jq"
OUTPUT=$(oc-mirror version --output json | jq --color-output)
mecho "$OUTPUT"
mecho
mecho
new_page

# List releases..
command_text "$ oc-mirror list releases"
OUTPUT=$(oc-mirror list releases)
mecho "$OUTPUT"
new_page

mecho "This is the end..."
new_page
