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

# ---------------------------------------------------------
# OpenShift Pull Secret Handling
# ---------------------------------------------------------

# Ensure the destination directory exists
mkdir -p "$RESOURCES_DIR/chome/etc/crio"

PULLSECRET_FILE="$RESOURCES_DIR/chome/etc/crio/openshift-pull-secret"
PULLSECRET_JSON=""

if [ -f "$PULLSECRET_FILE" ]; then
  # Read file content directly..
  PULLSECRET_JSON=$(<"$PULLSECRET_FILE")
  echo " -> Pull Secret loaded from: $PULLSECRET_FILE"
fi

if [ -z "$PULLSECRET_JSON" ]; then
  echo "No Pull Secret found at $PULLSECRET_FILE!"
  read -r -p "Paste your minified pull-secret.json: " PULLSECRET_JSON  

  # Save the input to the file without adding a trailing newline
  echo -n "$PULLSECRET_JSON" > "$PULLSECRET_FILE"
  
  # Secure the file (read/write for owner only)
  chmod 600 "$PULLSECRET_FILE"
fi
## end of pull-secret.json handling..

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

# First prepapare the storage for microshift as it is a prerequisite..
if [ -b /dev/vdb ]; then
    
    # Create Physical Volume on the disk /dev/vdb
    pvcreate -y /dev/vdb
    
    # Create Volume Group named 'rhel' using the physical volume /dev/vdb
    vgcreate -y rhel /dev/vdb
fi

#
subscription-manager release --set=9.6

#
subscription-manager repos \
    --enable="rhocp-4.21-for-rhel-9-$(uname -m)-rpms" \
    --enable="fast-datapath-for-rhel-9-$(uname -m)-rpms"

#
dnf install -y microshift openshift-clients

#
firewall-offline-cmd --zone=trusted --add-source=10.42.0.0/16
firewall-offline-cmd --zone=trusted --add-source=169.254.169.1
firewall-offline-cmd --zone=public --add-port=6443/tcp

#
if [ -f /etc/crio/openshift-pull-secret ]; then
  chown root:root /etc/crio/openshift-pull-secret
  chmod 600 /etc/crio/openshift-pull-secret
fi

# Enable the MicroShift service to start on boot..
systemctl enable microshift.service

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
  /etc/crio/openshift-pull-secret
  /etc/microshift/config.yaml
  /usr/local/bin/init-cli.sh
  /usr/local/bin/check.sh
)

# Iterate over the list of files and add them to the update-ks.cfg..
for FILE in "${FILES_LIST[@]}"; do
    add_file_to_ks "$FILE"
done
