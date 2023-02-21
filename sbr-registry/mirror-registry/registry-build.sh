#!/bin/bash

#!/bin/bash

# Default values
REGISTRY_NAME="mregistry"
REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
STORAGE="/opt/registry/$REGISTRY_NAME"

USER_NAME=""
USER_PASSWD=""

source registry-data.sh

oc adm catalog build  \
    --insecure \
    --appregistry-org redhat-operators \
    --from=registry.redhat.io/openshift4/ose-operator-registry:v4.3 \
    --to=$REGISTRY_HOST:$REGISTRY_PORT/olm/redhat-operators:v1 -a ./pull-secret.json
