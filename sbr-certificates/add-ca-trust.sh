#!/bin/bash

# Default values
TLS_CERTIFICATE="nutius.com"
HOST="app01"

source ./data.sh


# * Add the required trusted CAs for the mirror in the cluster’s image configuration object:
#   https://docs.openshift.com/container-platform/4.3/installing/install_config/installing-restricted-networks-preparations.html#installation-restricted-network-samples_installing-restricted-networks-preparations

oc create configmap $TLS_CERTIFICATE --from-file=${HOST}=$STORAGE/certs/$TLS_CERTIFICATE-ca.crt -n openshift-config
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"'$TLS_CERTIFICATE'"}}}' --type=merge
