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


MARIADB_ROOT_PASSWORD=$(base64 -d /var/passwd/containers/mariadb/MARIADB_ROOT_PASSWORD | tr -d '\n')
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Check if the container is already running..
if sudo podman ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Container $CONTAINER_NAME is running => stopping..."
    sudo podman stop "$CONTAINER_NAME"
    sleep 2
else
    echo "Container $CONTAINER_NAME is not running."
fi

# Pull the latest image..
sudo podman pull docker.io/library/mariadb:latest

#  -v /var/containers/mariadb/mariadb.conf.d/51-server.cnf:/etc/mysql/mariadb.conf.d/51-server.cnf:Z \
sudo podman run \
  --name "$CONTAINER_NAME" \
  --log-driver=k8s-file \
  --log-opt path=/var/containers/mariadb/logs/mariadb_$TIMESTAMP.log \
  -v /var/containers/mariadb/data:/var/lib/mysql:Z \
  -p 3306:3306 \
  -e MARIADB_ROOT_PASSWORD="$MARIADB_ROOT_PASSWORD" \
  -it \
  docker.io/library/mariadb:latest
