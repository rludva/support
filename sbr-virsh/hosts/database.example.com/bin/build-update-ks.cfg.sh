#!/bin/bash
set -euo pipefail

#
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"

SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
BASEDIR="$(cd "$SCRIPT_FOLDER/.." && pwd)"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the VM host..
VM_NAME="$FOLDER_NAME"
RESOURCES_DIR="$PARENT_FOLDER"


#
#
#
cat << BUILD_UPDATE_KS_CFG_EOF > "$RESOURCES_DIR/update-ks.cfg"
#
# update-ks.cfg:
# - content of this file is going to be added to the end of %post section in the anaconda-ks.cfg
#
# Generated: $(date +"%Y-%m-%d %H:%M:%S")
# Host: $(hostname)
#

#
# Installation of database service via container..
# (Battery Included Installation)
#
dnf install -y container-tools

# Install mariadb package as it provides mysqldump utility..
dnf install -y mariadb

# Default firewall for database..
firewall-offline-cmd --add-service=3306

# Prepare container specific files and directories
mkdir --parents "/var/containers/mariadb-service"
mkdir --parnets "/var/containers/mariadb-service/backup"
mkdir --parnets "/var/containers/mariadb-service/bin"
mkdir --parnets "/var/containers/mariadb-service/data"
mkdir --parnets "/var/containers/mariadb-service/logs"

# Generate MariaDB root password and store it in a file..
MARIADB_ROOT_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-16)"
MARIADB_ROOT_PASSWORD_FILE="/var/containers/mariadb-service/.MARIADB_ROOT_PASSWORD"

# Store the password in base64 encoding for later use in the administrative scripts..
echo -n "\$MARIADB_ROOT_PASSWORD" | base64 > "\$MARIADB_ROOT_PASSWORD_FILE"
chmod o-r "\$MARIADB_ROOT_PASSWORD_FILE"

# Set permissions for the container files and directories..
setfacl --recursive --modify u:{{USER_NAME}}:rwx /var/containers
setfacl --recursive --modify g:{{GROUP_NAME}}:rwx /var/containers

# Pull the latest MariaDB image..
podman pull docker.io/library/mariadb:latest

BUILD_UPDATE_KS_CFG_EOF

#
# Function to add a file to the update-ks.cfg in base64 encoding..
add_file_to_ks() {
    local FILE_PATH="$1"

    # 0. Calculate paths..
    local LOCAL_SRC="$PARENT_FOLDER/chome/${FILE_PATH}"
    local KS_FILE="$RESOURCES_DIR/update-ks.cfg"

    #
    local VM_DEST=$(echo "$FILE_PATH" | sed 's|^/home/user|/home/{{USER_NAME}}|')

    echo "add_file_to_ks(): $LOCAL_SRC -> $VM_DEST"

    # 1. Prepare the heredoc start in update-ks.cfg..
    cat << BUILD_UPDATE_KS_CFG_EOF >> "$KS_FILE"
#
#  Adding file: $VM_DEST
mkdir --parents "\$(dirname $VM_DEST)"
cat << FILE_EOF > $VM_DEST.b64
BUILD_UPDATE_KS_CFG_EOF

    # 2. Insert the base64 content..
    base64 -w0 "$LOCAL_SRC" >> "$KS_FILE"

    # 3. Finish the heredoc in update-ks.cfg..
    cat << BUILD_UPDATE_KS_CFG_EOF >> "$KS_FILE"

FILE_EOF

# Decode the base64 content on the VM..
base64 --decode "${VM_DEST}.b64" > "$VM_DEST"
rm "${VM_DEST}.b64"

# If the file is a script, make it executable..
if [ "\$(head -c 2 "$VM_DEST")" = "#!" ]; then
    chmod +x "$VM_DEST"
fi
# End of adding file
#

BUILD_UPDATE_KS_CFG_EOF
}

FILES_LIST=(
    "/var/containers/mariadb-service/bin/backup.sh"
    "/var/containers/mariadb-service/bin/backup_all.sh"
    "/var/containers/mariadb-service/bin/cli.sh"
    "/var/containers/mariadb-service/bin/deploy.sh"
)

# Iterace přes pole
for FILE in "${FILES_LIST[@]}"; do
    add_file_to_ks "$FILE"
done
