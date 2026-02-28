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
# Scripts that are for this instance of build script!
SAMBA_USER_NAME=$(get_input "Samba User Name" "samba_user_name" "samba")
SAMBA_USER_GROUP=$(get_input "Samba User Group" "samba_user_group" "samba")
SAMBA_USER_PASSWORD=$(get_input "Samba User Password" "samba_user_password" "$(gen_pass)")
SAMBA_USER_ID=$(get_input "Samba User ID (UID)" "samba_user_uid" "1001")
SAMBA_SHARE_FOLDER=$(get_input "Samba Share Folder Path" "samba_share_folder" "/srv/share")

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

# Install Samba server and related packages..
dnf install -y samba samba-common samba-client

# We will use the initial normal user name and password as the samba credentials..
# Samba username: $SAMBA_USER_NAME
# Samba password: $SAMBA_USER_PASSWORD

# Create a group for Samba users (optional, but good practice)..
groupadd "$SAMBA_USER_GROUP"

# Create a Linux user for Samba access and assign the primary group directly..
useradd -u "$SAMBA_USER_ID" -g "$SAMBA_USER_GROUP" "$SAMBA_USER_NAME"

# Set Linux password non-interactively..
echo "${SAMBA_USER_NAME}:${SAMBA_USER_PASSWORD}" | chpasswd

# Add the user to Samba and set the password non-interactively..
(echo "${SAMBA_USER_PASSWORD}"; echo "${SAMBA_USER_PASSWORD}") | smbpasswd -s -a "${SAMBA_USER_NAME}"

# Create a simple directory to share..
mkdir -p "$SAMBA_SHARE_FOLDER"

# Set permissions for the shared directory..
chown "root:$SAMBA_USER_GROUP" "$SAMBA_SHARE_FOLDER"


# The magic of SGID (the leading number 2)
# 2 = SGID (new files and directories inherit the '$SAMBA_USER_GROUP' group)
# 7 = owner (root) can read, write, and execute
# 7 = members of the '$SAMBA_USER_GROUP' group can read, write, and execute
# 0 = others have no access
chmod 2770 "$SAMBA_SHARE_FOLDER"

# --- REQUIRED FOR SELINUX ---
semanage fcontext -a -t samba_share_t "$SAMBA_SHARE_FOLDER(/.*)?"
restorecon -R -v "$SAMBA_SHARE_FOLDER"

# We will not use this SELinux configuration..
#setsebool -P samba_export_all_rw 1

# 1. Eneble default firewall rules for Samba..
firewall-offline-cmd --add-service=samba

# Backup the default smb.conf to prevent it from interfering with our custom configuration later..
mv /etc/samba/smb.conf /etc/samba/smb.conf.origin

cat << SMB_EOF > /etc/samba/smb.conf
# See smb.conf.example for a more detailed config file or
# read the smb.conf manpage.
# Run 'testparm' to verify the config is correct after
# you modified it.
#

# -----------------------------------------------------------------------------
# Original of smb.conf is moved to /etc/samba/smb.conf.origin 
# to prevent it from interfering with our custom configuration here.
# -----------------------------------------------------------------------------

[global]
	workgroup = WORKGROUP
	security = user
	server min protocol = NT1
	server max protocol = NT1
	ntlm auth = yes
	lanman auth = yes
	client lanman auth = yes
	map to guest = never

	passdb backend = tdbsam
	printing = cups
	printcap name = cups
	load printers = yes
	cups options = raw

	# Install samba-usershares package for support
	include = /etc/samba/usershares.conf

[share]
  path = $SAMBA_SHARE_FOLDER
  comment = Samba Shared Folder
  browseable = yes
  writable = yes
  valid users = @$SAMBA_USER_GROUP
  force create mode = 0660
  force directory mode = 2770   
SMB_EOF

# Enable and start Samba services..
systemctl enable smb nmb
systemctl start smb nmb


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
  "/usr/local/bin/samba-add-user.sh"
)

# Iterace přes pole
for FILE in "${FILES_LIST[@]}"; do
    add_file_to_ks "$FILE"
done
