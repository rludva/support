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

# 1. Creation of ipset for blacklisted IPs..
firewall-offline-cmd --new-ipset=blacklist --type=hash:ip

# 2. Adding the ipset to the drop zone..
firewall-offline-cmd --zone=drop --add-source=ipset:blacklist

# 3. Adding blacklisted IPs to the ipset..
firewall-offline-cmd --ipset=blacklist --add-entry=193.46.255.7
firewall-offline-cmd --ipset=blacklist --add-entry=193.32.162.145
firewall-offline-cmd --ipset=blacklist --add-entry=165.232.178.116

# 4. The rest of blacklist scripts are going to be added into /usr/local/bin..
mkdir /usr/local/bin

# 5. Install net-tools package (ether-wake)
#    Better to have it installed even the fackt that we use python to generate the WOL packet..
dnf install -y net-tools

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
 "/var/data/blacklist.ips"
 "/var/data/whitelist.ips"
 "/usr/local/bin/block-ip.sh"
 "/usr/local/bin/build-blacklist.sh"
 "/usr/local/bin/bulk-block.sh"
 "/usr/local/bin/create-ipset-blacklist.sh"
 "/usr/local/bin/extract-user.sh"
 "/usr/local/bin/get-entries-blacklist.sh"
 "/usr/local/bin/get-entries-whitelist.sh"
 "/home/user/.local/bin/bashrc_a_comp.sh"
 "/home/user/.bashrc_example"
)

# Iterace přes pole
for FILE in "${FILES_LIST[@]}"; do
    add_file_to_ks "$FILE"
done
