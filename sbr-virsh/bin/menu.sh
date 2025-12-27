#!/bin/bash
set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
HOSTSDIR="$BASEDIR/hosts"

if [[ ! -d "$HOSTSDIR" ]]; then
    echo "Host directory not found: $HOSTSDIR"
    exit 1
fi


function choose_host_folder() {
  local folder="$1"
  
  # Check if the directory exists
  if [ ! -d "$folder" ]; then
    echo "Error: Directory '$folder' does not exist." >&2
    return 1
  fi

  # 1. Load folders into an array (names only, not paths)
  local options=()
  local dir_path
  
  # Iterate through all folders in the given location
  for dir_path in "$folder"/*/; do
    # Check if globbing found an actual directory (in case of an empty directory)
    if [ -d "$dir_path" ]; then
      # basename gets "folder_name" from "/path/to/folder_name/"
      options+=("$(basename "$dir_path")")
    fi
  done

  # If the folder is empty
  if [ ${#options[@]} -eq 0 ]; then
    echo "Error: No folders found in '$folder'." >&2
    return 1
  fi

  # 2. Display menu using 'select'
  # Set the prompt for the user
  PS3="Select a folder number (Enter to show menu): "
  
  # Redirect select menu to stderr (>&2) so we can capture stdout
  select opt in "${options[@]}" "Quit"; do
    case $opt in
      "Quit")
        return 1
        ;;
      *)
        if [ -n "$opt" ]; then
          echo "$opt" # Return the selected value to stdout
          return 0
        else
          echo "Invalid selection, please try again." >&2
        fi
        ;;
    esac
  done
}

#
echo "Reading hosts from: $HOSTSDIR" >&2
SELECTED_HOST=$(choose_host_folder "$HOSTSDIR")

# 
if [ -n "$SELECTED_HOST" ]; then
  echo " -> User selected: $SELECTED_HOST"
else
  echo " -> Selection cancelled or error occurred."
  exit 1
fi
