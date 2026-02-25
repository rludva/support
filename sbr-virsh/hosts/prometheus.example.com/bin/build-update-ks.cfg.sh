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

# 2. Eneble default firewall rules for Prometheus..
firewall-offline-cmd --add-port=9090/tcp
semanage port -a -t prometheus_port_t -p tcp 9090 || semanage port -m -t http_port_t -p tcp 9090

# 3. Povolení portu pro Grafanu (obvykle už spadá pod http_port_t)
# Node Exporter
firewall-offline-cmd --add-port=9100/tcp
semanage port -a -t prometheus_node_exporter_port_t -p tcp 9100 || semanage port -a -t http_port_t -p tcp 9100

# Alertmanager
firewall-offline-cmd --add-port=9093/tcp
semanage port -a -t http_port_t -p tcp 3000 || semanage port -m -t http_port_t -p tcp 3000

dnf install -y git
dnf install -y ansible-core

##
## ansible.posix
mkdir -p /usr/share/ansible/collections

# 1. Musíme exportovat HOME, aby Ansible věděl, kam ukládat cache
export HOME=/root
export PATH=$PATH:/usr/bin:/usr/local/bin

# 2. Vynutíme neinteraktivní režim bez barev a bez pokusů o přístup k terminálu
# Použijeme plnou cestu k binárce a potlačíme chyby spojené s TTY
ANSIBLE_NOCOLOR=1 ANSIBLE_LOG_PATH=/root/ansible-galaxy-debug.log \
echo "Instaluji kolekci..."
ansible-galaxy collection install ansible.posix \
    -p /usr/share/ansible/collections \
    --force \
    < /dev/null > /root/galaxy_output.log 2>&1## 
##
##


mkdir -p /var/git/github.com/rludva
setfacl -R -m u:rludva:rwx,g:rludva:rwx /var/git
setfacl -R -d -m u:rludva:rwx,g:rludva:rwx /var/git

git clone https://github.com/rludva/support.git /var/git/github.com/rludva/support 

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
)

# Iterace přes pole
for FILE in "${FILES_LIST[@]}"; do
    add_file_to_ks "$FILE"
done
