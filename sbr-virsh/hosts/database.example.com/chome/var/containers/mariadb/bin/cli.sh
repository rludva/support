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

# Zjistí, jestli kontejner běží
if ! sudo podman ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Kontejner $CONTAINER_NAME neběží."
    exit 1
fi

mysql --user="root" --password="$MARIADB_ROOT_PASSWORD" --host="127.0.0.1" --port="3306"
#sudo podman exec -it mariadb mysql --user=root --password="$MARIADB_ROOT_PASSWORD"
