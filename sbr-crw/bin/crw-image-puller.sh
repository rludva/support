#! /usr/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

function information() {
  MESSAGE="$1"
  echo
  echo -e "${YELLOW}${MESSAGE}${RESET}"
}

function print_yaml() {
  FILE="$1"
  echo "Content of: $FILE"

  HIGHLIGHT=$(which highlight 2>/dev/null)
  if [ -z "$HIGHLIGHT" ]; then
    cat "$FILE" 
    echo
    return
  fi

  cat "$FILE" | highlight --out-format=xterm256 --syntax=yaml
  echo
}

function sleepx() {
 count="$1"
 while [ $count -gt 0 ]; do
   echo -ne "${MAGENTA}We are wating for ${count}s..${RESET}\033[0K\r"
   sleep 1
   ((count--))
  done

  echo -ne "\033[0K\r"
}

curl -sSLo- https://raw.githubusercontent.com/redhat-developer/codeready-workspaces-images/crw-2.15-rhel-8/codeready-workspaces-operator-metadata-generated/manifests/codeready-workspaces.csv.yaml \
  | yq -r '.spec.relatedImages[]'
