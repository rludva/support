#!/bin/bash

# Default values
REGISTRY_NAME="mirror-registry"
REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
STORAGE="/opt/registry/$REGISTRY_NAME"

USER_NAME=""
USER_PASSWD=""

source registry-data.sh

COMMAND="_catalog"
curl -u $USER_NAME:$USER_PASSWD. -k https://$REGISTRY_HOST:$REGISTRY_PORT/v2/$COMMAND

