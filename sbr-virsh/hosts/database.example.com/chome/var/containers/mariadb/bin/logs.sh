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


TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
sudo podman logs -f $CONTAINER_NAME 2>&1 | sudo tee /var/containers/"$CONTAINER_NAME"/logs/"$CONTAINER_NAME"_"$TIMESTAMP".log
