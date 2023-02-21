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

function clear_file() {
  FILENAME="$1"
  if [ -e "$FILENAME" ]; then
    rm "$FILENAME"
    touch "$FILENAME"
  fi
}

SLEEP_SECONDS=0.5

COMMAND1_FILE="/tmp/sbr-shift-logging-dashboard-command1.txt"
echo "not available" > "$COMMAND1_FILE"

COMMAND2_FILE="/tmp/sbr-shift-logging-dashboard-command2.txt"
echo "not available" > "$COMMAND2_FILE"

COMMAND3_FILE="/tmp/sbr-shift-logging-dashboard-command3.txt"
echo "not available" > "$COMMAND3_FILE"

while true; do

  if [ -s "$COMMAND1_FILE" ]; then
    openshift_logging_pods=$(cat $COMMAND1_FILE)
    clear_file "$COMMAND1_FILE"
    oc get pods -n openshift-logging -o wide > "$COMMAND1_FILE" &
  fi

  if [ -s "$COMMAND2_FILE" ]; then
    openshift_operator_redhat_pods=$(cat $COMMAND2_FILE)
    clear_file "$COMMAND2_FILE"
    oc get pods -n openshift-operators-redhat -o wide> $COMMAND2_FILE &
  fi

  if [ -s "$COMMAND3_FILE" ]; then
    openshift_logging_operator_logs=$(cat $COMMAND3_FILE)
    clear_file "$COMMAND3_FILE"
    oc logs $(oc get pods -o name -n openshift-logging --selector name=cluster-logging-operator) -n openshift-logging | \
      tail -n 10 | \
      highlight --out-format=xterm256 --syntax=json > $COMMAND3_FILE &
  fi


  clear
  echo "${BOLD}${YELLOW}OpenShift Logging Terminal Dashboard..${RESET}"
  echo "${BOLD}${YELLOW}================================================${RESET}"

  information "OpenShift Logging pods in [openshift-logging].."
  echo "$openshift_logging_pods"

  information "ElasticSearch Operator pods [openshift-operatos-redhat].."
  echo "$openshift_operator_redhat_pods"

  information "OpenShift Logging Operator logs.."
  echo "$openshift_logging_operator_logs"

  sleep $SLEEP_SECONDS
done
