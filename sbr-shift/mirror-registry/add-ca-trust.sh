#!/bin/bash

# Default values
REGISTRY_NAME="mregistry"
REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
STORAGE="/opt/registry/$REGISTRY_NAME"

source registry-data.sh


# * Add the required trusted CAs for the mirror in the cluster’s image configuration object:
#   https://docs.openshift.com/container-platform/4.3/installing/install_config/installing-restricted-networks-preparations.html#installation-restricted-network-samples_installing-restricted-networks-preparations

#```bash
#$ oc create configmap registry-config --from-file=${MIRROR_ADDR_HOSTNAME}..5000=$path/ca.crt -n openshift-config
#$ oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge
#```

oc create configmap $REGISTRY_NAME --from-file=${REGISTRY_HOST}..${REGISTRY_PORT}=$STORAGE/certs/$REGISTRY_NAME-ca.crt -n openshift-config
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"'$REGISTRY_NAME'"}}}' --type=merge
