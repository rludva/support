#!/bin/bash

#!/bin/bash

# Default values
REGISTRY_NAME="mirror-registry"
REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
STORAGE="/opt/registry/$REGISTRY_NAME"

USER_NAME=""
USER_PASSWD=""

source registry-data.sh

HOST=$(oc get route default-route -n openshift-image-registry --template='{{.spec.host}}')
echo "OCP Registry: $HOST"
sudo podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $HOST
curl -u $(oc whoami):$(oc whoami -t) -k https://$HOST/v2/_catalog | jq
read "Press <Enter> to continue.."
exit

OCP_REGISTRY="$HOST"
oc adm catalog mirror $REGISTRY_HOST:$REGISTRY_PORT/olm/redhat-operators:v1 $OCP_REGISTRY
