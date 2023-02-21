#!/bin/bash

source registry-data.sh

REGISTRY_HOST="localhost"
REGISTRY_PORT=5000
OCP_REGISTRY="localhost:5005"
oc adm catalog mirror \
	$REGISTRY_HOST:$REGISTRY_PORT/olm/redhat-operators:v2 \
	$OCP_REGISTRY/openshift/redhat-operators:v2 \
	-a ./pull-secret.json \
	--rm \
	--insecure
