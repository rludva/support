#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
UNDERLINE=$(tput smul)
BLINK=$(tput blink)
RESET=$(tput sgr0)

function sleepx() {
 count="$1"
 if [ -z "$count" ]; then
   count=60
 fi
 echo
 while [ $count -gt 0 ]; do
   echo -ne "${MAGENTA}We are wating for ${count}s..${RESET}\033[0K\r"
   read -t 1 -s -N 1 input
   if [ ! -z "$input" ]; then
     break
   fi
   ((count--))
  done

  echo -ne "\033[0K\r"
}
