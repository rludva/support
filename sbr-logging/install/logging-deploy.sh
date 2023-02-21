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

information "01 - Create ES Operator Namespace.."
print_yaml 01-es-operator-namespace.yaml
oc create -f 01-es-operator-namespace.yaml
sleepx 20

information "02 - Create OpenShift Logging Operator Namespace.."
print_yaml 02-openshift-logging-operator-namespace.yaml
oc create -f 02-openshift-logging-operator-namespace.yaml
sleepx 20

information "03 - 01 - Create ES OperatorGroup.."
print_yaml 03-01-es-operator-group.yaml
oc create -f 03-01-es-operator-group.yaml
sleepx 20

information "03 - 02 - Create ES Operator Subscription.."
print_yaml 03-02-es-operator-subscription.yaml
oc create -f 03-02-es-operator-subscription.yaml
sleepx 20

information "03-03 - [Verify the Elasticsearch operator installation..]\nThere should be an OpenShift Elasticsearch Operator in each namespace."
oc get csv -n openshift-logging
oc get csv -n openshift-operators-redhat
sleepx 20

information "04 - 01 - Create Logging OperatorGroup.."
print_yaml 04-01-logging-operator-group.yaml
oc create -f 04-01-logging-operator-group.yaml
sleepx 20

information "04 - 02 - Create Logging Operator Subscription.."
print_yaml 04-02-logging-operator-subscription.yaml
oc create -f 04-02-logging-operator-subscription.yaml
sleepx 20


information "04-03 - [Verify the logging operator installation..]\nThere should be a Red Hat OpenShift Logging Operator in the openshift-logging namespace."
oc get csv -n openshift-logging
sleepx 20

information "05 - Create OpenShift Logging Instance.."
print_yaml 05-openshift-logging-instance.yaml
oc create -f 05-openshift-logging-instance.yaml
sleepx 20

information "06 - Verify OpenShift Logging Pods.."
oc get -w pods -n openshift-logging
