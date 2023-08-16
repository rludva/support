#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

INFO_COLOR="${YELLOW}"

function information() {
  MESSAGE="$1"
  echo -e "${YELLOW}${MESSAGE}${RESET}"
}

function warning() {
  MESSAGE="$1"
  echo -e "${RED}${MESSAGE}${RESET}"
}

#FOLDER="devspaces-dump-$(date +%Y-%m-%d_%H-%M-%S)"
FOLDER="devspaces-dump-$(date +%Y-%m-%d)"
mkdir $FOLDER

echo "Dumping devspaces to $FOLDER"

echo " - processing clusterversion.."
oc get clusterversion > $FOLDER/01-clusterversion.txt

echo " - processing csv, installplans and subscriptions from all namespaces.."
oc get csv -A > $FOLDER/all-csv.txt
oc get installplans -A > $FOLDER/all-installplans.txt
oc get subscriptions -A > $FOLDER/all-subscriptions.txt

echo " - checking all namespaces in the cluster.."
oc get namespaces > $FOLDER/all-namespaces.txt

echo " - checking all nodes in the cluster.."
oc get nodes > $FOLDER/all-nodes.txt

echo " - processing csv, installplans and subscriptions from openshift-operators namespace.."
oc get csv -n openshift-operators > $FOLDER/02-csv.txt
oc get installplans -n openshift-operators > $FOLDER/02-installplans.txt
oc get subscriptions -n openshift-operators > $FOLDER/02-subscriptions.txt

echo " - checking CheClusters CRD.."
oc get checlusters -A > $FOLDER/all-checusters.txt

# There should be only one CheCluster CRD in the cluster..

export DEFAULT_CHECLUSTER_NAME="devspaces"
export DEFAULT_CHECLUSTER_NAMESPACE_NAME="openshift-devspaces"
export DEFAULT_UPSTREAM_CHECLUSTER_NAME="eclipse-che"
export DEFAULT_OPENSHIFT_OPERATORS_NAMESPACE_NAME="openshift-operators"

export NUMBER_OF_CHECLUSTERS=$(oc get checlusters -A -o name | wc -l)
export CHECLUSTER_NAMESPACE_NAME=$(oc get checlusters -A -o go-template='{{range .items}}{{.metadata.namespace}}{{"\n"}}{{end}}')
export CHECLUSTER_NAME=$(oc get checlusters -A -o go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')

echo " > Number of CheClusters: ${INFO_COLOR}$NUMBER_OF_CHECLUSTERS${RESET}"
echo " > CheCluster namespace name: ${INFO_COLOR}$CHECLUSTER_NAMESPACE_NAME${RESET}"
echo " > CheCluster name: ${INFO_COLOR}$CHECLUSTER_NAME${RESET}"

oc get checlusters -n $CHECLUSTER_NAMESPACE_NAME $CHECLUSTER_NAME -o yaml > $FOLDER/03-checluster.yaml

function test_number_of_checluster_should_be_one() {
  if [ "$NUMBER_OF_CHECLUSTERS" -ne 1 ]; then
    echo    " - test: Number of checlusters is expected to be one: ${RED}fail${RESET}"
    warning "   > WARNING: There are more than one CheCluster CRD in the cluster. Please check the output of the following command:"
    warning "   > oc get checlusters -A"
    oc get checlusters -A
  else
    echo    " - test: Number of checlusters is expected to be one: ${GREEN}ok${RESET}"
  fi
}
test_number_of_checluster_should_be_one

function test_checluster_namespace_name() {
  if [ "$CHECLUSTER_NAMESPACE_NAME" = "$DEFAULT_OPENSHIFT_OPERATORS_NAMESPACE_NAME" ]; then
    echo    " - test: CheCluster namespace name is not $DEFAULT_OPENSHIFT_OPERATORS_NAMESPACE_NAME: ${RED}fail${RESET}"
    warning "   > WARNING: CheCluster namespace name is $CHECLUSTER_NAMESPACE_NAME: it is a good practice to install it out of $DEFAULT_OPENSHIFT_OPERATORS_NAMESPACE_NAME namespace..."
    warning "   >          The default CheCluster namespace name is expected to be: $DEFAULT_CHECLUSTER_NAMESPACE_NAME"
  else
    echo    " - test: CheCluster namespace name is not $DEFAULT_OPENSHIFT_OPERATORS_NAMESPACE_NAME: ${GREEN}ok${RESET}"
  fi
}
test_checluster_namespace_name

function test_checluster_namespace_name_is_default_one() {
  if [ "$CHECLUSTER_NAMESPACE_NAME" != "$DEFAULT_CHECLUSTER_NAMESPACE_NAME" ]; then
    echo    " - test: CheCluster namespace name is $DEFAULT_CHECLUSTER_NAMESPACE_NAME: ${RED}fail${RESET}"
    warning "   > WARNING: CheCluster namespace name is $CHECLUSTER_NAMESPACE_NAME: it is a good practice to install it in $DEFAULT_CHECLUSTER_NAMESPACE_NAME namespace..."
  else
    echo    " - test: CheCluster namespace name is $DEFAULT_CHECLUSTER_NAMESPACE_NAME: ${GREEN}ok${RESET}"
  fi
}
test_checluster_namespace_name_is_default_one

function test_not_upstream_instance_of_eclipse-che() {
  if [ "$CHECLUSTER_NAME" = "eclipse-che" ]; then
    echo    " - test: CheCluster name is not $DEFAULT_UPSTREAM_CHECLUSTER_NAME: ${RED}fail${RESET}"
    warning "   > WARNING: CheCluster name is $CHECLUSTER_NAME: it looks like upstream EclipseChe installation which is not supported.."
  else
    echo    " - test: CheCluster name is not $DEFAULT_UPSTREAM_CHECLUSTER_NAME: ${GREEN}ok${RESET}"
  fi
}
test_not_upstream_instance_of_eclipse-che

function test_default_checluster_name() {
  if [ "$CHECLUSTER_NAME" != "devspaces" ]; then
    echo    " - test: CheCluster name is $DEFAULT_CHECLUSTER_NAME: ${RED}fail${RESET}"
    warning "   > WARNING: CheCluster name is $CHECLUSTER_NAME: it looks like non-default CheCluster name.."
    warning "   >          The default CheCluster name is expected to be: $DEFAULT_CHECLUSTER_NAME"
  else
    echo    " - test: CheCluster name is $DEFAULT_CHECLUSTER_NAME: ${GREEN}ok${RESET}"
  fi
}
test_default_checluster_name
