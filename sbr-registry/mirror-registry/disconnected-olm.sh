#!/bin/bash

oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# Default values
REGISTRY_NAME="mirror-registry"
REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
STORAGE="/opt/registry/$REGISTRY_NAME"

USER_NAME=""
USER_PASSWD=""

source registry-data.sh

oc adm catalog mirror \
		registry.redhat.io/olm/redhat-operators:v1 \
		$REGISTRY_HOST:$REGISTRY_POD \
		--insecure \
		-a ./pull-secret.json


oc adm catalog build \
		--appregistry-org redhat-operators \
		--to=$REGISTRY_HOST:$REGISTRY_PORT/olm/redhat-operators:v2 \
		--insecure \
		-a ./pull-secret.json

HOST=$(oc get route default-route -n openshift-image-registry --template='{{.spec.host}}')
echo "OCP Registry: $HOST"
sudo podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $HOST
curl -u $(oc whoami):$(oc whoami -t) -k https://$HOST/v2/_catalog | jq
read "Press <Enter> to continue.."

HOST=$(oc get route default-route -n openshift-image-registry --template='{{.spec.host}}')
OCP_REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{.spec.host}}')
oc adm catalog mirror \
		$REGISTRY_HOST:$REGISTRY_PORT/olm/redhat-operators:v1 \
		$OCP_REGISTRY \
		--insecure \
		-a ./pull-secret.json

