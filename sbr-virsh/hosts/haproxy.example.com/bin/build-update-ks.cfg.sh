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

# Install haproxy..
dnf install -y haproxy

# Enable http and https (80, 443)..
firewall-offline-cmd --add-service=http --add-service=https

# The 80 and 443 are usully in the standard configuration already set to http_port_t..
# So use the || /bin/true to ignore errors if already set!
semanage port -a -t http_port_t -p tcp 80 || /bin/true
semanage port -a -t http_port_t -p tcp 443 || /bin/true

# Enable 22624/tcp: Machine Config Server (MCS)
firewall-offline-cmd --add-port=22624/tcp
semanage port -a -t http_port_t -p tcp 22624

# Enable 6443/tcp: OpenShift/Kubernetes API
firewall-offline-cmd --add-port=6443/tcp
semanage port -a -t http_port_t -p tcp 6443

# Registry
firewall-offline-cmd --add-port=5000-5001/tcp
semanage port -a -t http_port_t -p tcp 5001
semanage port -a -t http_port_t -p tcp 5000


# Allow haproxy to connect to any port..
setsebool -P haproxy_connect_any 1

# Make copy of original haproxy configoruation..
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.origin

BUILD_UPDATE_KS_CFG_EOF

#
# Function to add a file to the update-ks.cfg in base64 encoding..
add_file_to_ks() {
   local FILE_PATH="$1"
    
    # 0. Calculate paths..
    local VM_DEST="$FILE_PATH"
    local LOCAL_SRC="$PARENT_FOLDER/chome/${FILE_PATH}"
    local KS_FILE="$RESOURCES_DIR/update-ks.cfg"

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
)

# Iterace přes pole
for FILE in "${FILES_LIST[@]}"; do
    add_file_to_ks "$FILE"
done
