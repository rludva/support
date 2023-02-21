#!/bin/bash

source registry-data.sh

REGISTRY_HOST="personal.local.nutius.com"
REGISTRY_PORT=5000
OCP_REGISTRY="registry.redhat.io"

OCP_RELEASE="4.9.18"
LOCAL_REGISTRY="personal.local.nutius.com:5000"
LOCAL_REPOSITORY="ocp4/openshift4"
PRODUCT_REPO="openshift-release-dev"
LOCAL_SECRET_JSON="./pull-secret.json"
RELEASE_NAME="ocp-release"
ARCHITECTURE="x86_64"
REMOVABLE_MEDIA_PATH="/archiv/_REGISTRY"

oc adm release mirror -a ${LOCAL_SECRET_JSON} \
	--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
	--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
	--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} \
	--insecure
	#--dry-run
