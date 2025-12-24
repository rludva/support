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


#
# Let's Encrypt specific setup:

# Enable http 80
firewall-offline-cmd --add-service=http

# The 80/tcp is usually in the standard configuration already set to http_port_t..
# So use the || /bin/true to ignore errors if already set!
semanage port -a -t http_port_t -p tcp 80 || /bin/true

# Enable CodeReady Builder repository
subscription-manager repos --enable codeready-builder-for-rhel-10-x86_64-rpms

# Install required packages
dnf install -y python3 python3-devel augeas-devel gcc openssl-devel

# Setup Certbot in a virtual environment..
python3 -m venv /opt/certbot/

# Upgrade pip and install certbot
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot

# Create symlink for certbot command--
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Setup cron job for automatic certificate renewal..
echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

cat <<EOF > /usr/local/bin/renew-hook.sh
#!/bin/bash
#
# Distribution logic to deploy new certificates after renewal..
#
# Use with sudo certbot renew --deploy-hook /usr/local/bin/renew-hook.sh
# $ certbot certonly --standalone -d service1.apps.example.com --deploy-hook /usr/local/bin/renew-hook.sh

EOF
chmod +x /usr/local/bin/renew-hook.sh

# End of LetsEncrypt specific setup
# 

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
