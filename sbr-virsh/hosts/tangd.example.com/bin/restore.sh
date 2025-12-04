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

# Now define the folder with tangd.service database..
TANGD_DB_FOLDER="/var/db/tang"

# Backup root folder for the tangd.service database..
BACKUP_FOLDER="$PARENT_FOLDER/chome/var/db/tang"

# === 2. Verify backup existence ===
if [ ! -d "$BACKUP_FOLDER" ]; then
    echo "ERROR: Backup directory does not exist: $BACKUP_FOLDER"
    exit 1
fi

echo "=== Starting TANG database restore on $VM_NAME ==="
echo "Source: $BACKUP_FOLDER/"
echo "Target: $VM_NAME:$TANGD_DB_FOLDER/"

# === 3. Perform file restore (Rsync) ===
# --rsync-path="sudo rsync" ensures write access to the protected directory on the server
rsync --archive --verbose --delete \
      --rsync-path="sudo rsync" \
      "$BACKUP_FOLDER/" \
      "$USER@$VM_NAME:$TANGD_DB_FOLDER/"

# === 4. Fix permissions (Post-Restore Hook) ===
# Since the local backup belongs to the current user, 
# we must explicitly set the owner to 'tang' on the server; 
# otherwise, the service will not start.
echo "=== Fixing permissions on the remote server ==="

ssh "$USER@$VM_NAME" "bash -s" <<EOF
    set -e
    echo 'Setting owner to tang:tang...'
    sudo chown -R tang:tang $TANGD_DB_FOLDER
    
    echo 'Setting secure permissions (700 for dir, 440 for keys)...'
    sudo chmod 700 $TANGD_DB_FOLDER
    sudo chmod 440 $TANGD_DB_FOLDER/*.jwk   
EOF