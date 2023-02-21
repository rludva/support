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

function information() {
  MESSAGE="$1"
  echo
  echo "${YELLOW}${MESSAGE}${RESET}"
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


information "01 - Remove ClusterLogging Instance.."
oc delete ClusterLogging instance
sleepx 50

information "02 - 01 - Remove ClusterLogging Subscription.."
oc delete subscription cluster-logging -n openshift-logging
sleepx 15

information "02 - 02 - Remove ClusterLogging OperatorGroup.."
oc delete operatorgroup cluster-logging -n openshift-logging
sleepx 15

information "03 - 01 - Remove ElasticSearch Operator Subscription.."
oc delete subscription elasticsearch-operator -n openshift-operators-redhat
sleepx 15

information "03 - 02 - Remove ElasticSearch OperatorGroup.."
oc delete operatorgroup openshift-operators-redhat -n openshift-operators-redhat
sleepx 15

information "04 - Remove OpenShift Logging Custom Resource Definitions"
oc delete crd/clusterlogforwarders.logging.openshift.io
oc delete crd/clusterloggings.logging.openshift.io
oc delete crd/elasticsearches.logging.openshift.io
oc delete crd/kibanas.logging.openshift.io
sleepx 15

information "05 - 01 - Delete OpenShift Logging Operator (csv).."
csv=$(oc get csv -o name -n openshift-logging | grep cluster-logging --color=never)
oc delete $csv -n openshift-logging
sleepx 15

information "05 - 02 - Delete ElasticSearch Operator (csv).."
csv=$(oc get csv -o name -n openshift-operators-redhat | grep elasticsearch-operator --color=never)
oc delete $csv -n openshift-operators-redhat
