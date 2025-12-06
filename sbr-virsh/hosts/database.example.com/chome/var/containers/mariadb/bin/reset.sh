#!/bin/bash
set -euo pipefail

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the container..
CONTAINER_NAME="$FOLDER_NAME"


# If the container is running, stop it.
if sudo podman ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Container $CONTAINER_NAME is running => stopping..."
    sudo podman stop "$CONTAINER_NAME"
    sleep 2
else
    echo "Container $CONTAINER_NAME is not running."
fi

sudo rm -rf /var/containers/$CONTAINER_NAME/data
sudo mkdir /var/containers/$CONTAINER_NAME/data
