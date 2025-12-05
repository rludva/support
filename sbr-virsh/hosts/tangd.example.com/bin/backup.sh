#!/bin/bash
set -euo pipefail

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"

# Now define the source folder with tangd.servcie database..
TANGD_DB_FOLDER="/var/db/tang"

# Create backup folder for the tangd.service database..
BACKUP_FOLDER="$PARENT_FOLDER/chome"

# Process the backup..
rsync --archive --verbose --relative --delete "$USER@$VM_NAME:$TANGD_DB_FOLDER/" "$BACKUP_FOLDER/"