#!/bin/bash
set -euo pipefail

#
VM_NAME="${1:?Usage: $0 <hostname>}"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
HOSTDIR="$BASEDIR/hosts/$VM_NAME"
RESOURCES_DIR="$HOSTDIR"
ANACONDA_KS_CFG_SKELETON_FILE="$BASEDIR/res/anaconda-ks.cfg.skel"

if [[ ! -d "$HOSTDIR" ]]; then
    echo "Host directory not found: $HOSTDIR"
    exit 1
fi

# -----------------------------------------------------
# Get input from user with defaults from file or hardcoded default..
function get_input() {
  local prompt_label="$1"                 # e.g., "User ID" => "User ID (default: 1000): "
  local file_path="$RESOURCES_DIR/$2"     # e.g., "user_uid" => "$RESOURCES_DIR/user_uid"
  local hard_default="$3"                 # e.g., "1000"

  # 1. Attempt to read from file
  # - Read the file content, stripping whitespace (newlines, spaces, tabs) (managed via read itself).
  local file_content=""
  if [ -f "$file_path" ]; then
    read -r file_content < "$file_path" || true
  fi

  # If we read something, use it as default value, otherwise, keep the original $default.
  local default="$hard_default"
  default="${file_content:-$default}"

  # 2. Prompt the user..
  local user_input

  # Read prompt must go to stderr to allow capturing the function output..
  read -p "$prompt_label (default: $default): " user_input >&2

  # 3. Output the result
  echo "${user_input:-$default}"

  # Write new value to file for future use..
  echo "${user_input:-$default}" > "$file_path"
}
# -----------------------------------------------------
# Generate a random password like..
function gen_pass() {
  openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 4 | paste -sd '-' -
}
# -----------------------------------------------------
ROOT_PASSWORD=$(get_input "Root Password" "root_password" "$(gen_pass)")
USER_NAME=$(get_input "User Name" "user_name" "$USER")
USER_PASSWORD=$(get_input "User Password" "user_password" "$(gen_pass)")
USER_ID=$(get_input "User ID" "user_uid" "1000")
# -----------------------------------------------------


# 2. Generate password hash..
ROOT_PASSWORD_HASH=$(openssl passwd -6 "$ROOT_PASSWORD")
USER_PASSWORD_HASH=$(openssl passwd -6 "$USER_PASSWORD")

# 3. Set user and group names and IDs..
GROUP_NAME=$USER_NAME
USER_ID=${USER_ID:-1000}
GROUP_ID=${USER_ID:-1000}

# 4. Generating SSH Keys..

# 4.1 ECDSA
SSH_HOST_ECDSA_PRIVATE_B64=""
SSH_HOST_ECDSA_PUBLIC_B64=""
if [ -f "$RESOURCES_DIR/ssh_host_ecdsa_key.b64" ]; then
  echo " -> Existing ECDSA host key found, reusing it."
  SSH_HOST_ECDSA_PRIVATE_B64=$(cat "$RESOURCES_DIR/ssh_host_ecdsa_key.b64")
  SSH_HOST_ECDSA_PUBLIC_B64=$(cat "$RESOURCES_DIR/ssh_host_ecdsa_key.pub.b64")
fi
if [ -z "$SSH_HOST_ECDSA_PRIVATE_B64" ] || [ -z "$SSH_HOST_ECDSA_PUBLIC_B64" ]; then
  echo " -> Generating new ECDSA host key.."
  TMP_KEY_ECDA=$(mktemp --dry-run)
  ssh-keygen -t ecdsa -b 521 -N "" -m PEM -f "$TMP_KEY_ECDA" >/dev/null 2>&1
  SSH_HOST_ECDSA_PRIVATE_B64=$(base64 -w0 "$TMP_KEY_ECDA")
  SSH_HOST_ECDSA_PUBLIC_B64=$(base64 -w0 "$TMP_KEY_ECDA.pub")
  rm -f "$TMP_KEY_ECDA" "$TMP_KEY_ECDA.pub"
  echo $SSH_HOST_ECDSA_PRIVATE_B64 > "$RESOURCES_DIR/ssh_host_ecdsa_key.b64"
  echo $SSH_HOST_ECDSA_PUBLIC_B64 > "$RESOURCES_DIR/ssh_host_ecdsa_key.pub.b64"
fi

# 4.2 ED25519
SSH_HOST_ED25519_PRIVATE_B64=""
SSH_HOST_ED25519_PUBLIC_B64=""
if [ -f "$RESOURCES_DIR/ssh_host_ed25519_key.b64" ]; then
  echo " -> Existing ED25519 host key found, reusing it."
  SSH_HOST_ED25519_PRIVATE_B64=$(cat "$RESOURCES_DIR/ssh_host_ed25519_key.b64")
  SSH_HOST_ED25519_PUBLIC_B64=$(cat "$RESOURCES_DIR/ssh_host_ed25519_key.pub.b64")
fi
if [ -z "$SSH_HOST_ED25519_PRIVATE_B64" ] || [ -z "$SSH_HOST_ED25519_PUBLIC_B64" ]; then
  echo " -> Generating new ED255 host key.."
  TMP_KEY_ED25519=$(mktemp --dry-run)
  ssh-keygen -t ed25519 -N "" -f "$TMP_KEY_ED25519" >/dev/null 2>&1
  SSH_HOST_ED25519_PRIVATE_B64=$(base64 -w0 "$TMP_KEY_ED25519")
  SSH_HOST_ED25519_PUBLIC_B64=$(base64 -w0 "$TMP_KEY_ED25519.pub")
  rm -f "$TMP_KEY_ED25519" "$TMP_KEY_ED25519.pub"
  echo $SSH_HOST_ED25519_PRIVATE_B64 > "$RESOURCES_DIR/ssh_host_ed25519_key.b64"
  echo $SSH_HOST_ED25519_PUBLIC_B64 > "$RESOURCES_DIR/ssh_host_ed25519_key.pub.b64"
fi


# 4.3 RSA
SSH_HOST_RSA_PRIVATE_B64=""
SSH_HOST_RSA_PUBLIC_B64=""
if [ -f "$RESOURCES_DIR/ssh_host_rsa_key.b64" ]; then
  echo " -> Existing RSA host key found, reusing it."
  SSH_HOST_RSA_PRIVATE_B64=$(cat "$RESOURCES_DIR/ssh_host_rsa_key.b64")
  SSH_HOST_RSA_PUBLIC_B64=$(cat "$RESOURCES_DIR/ssh_host_rsa_key.pub.b64")
fi
if [ -z "$SSH_HOST_RSA_PRIVATE_B64" ] || [ -z "$SSH_HOST_RSA_PUBLIC_B64" ]; then
  echo " -> Generating new RSA host key.."
  TMP_KEY_RSA=$(mktemp --dry-run)
  ssh-keygen -t rsa -N "" -f "$TMP_KEY_RSA" >/dev/null 2>&1
  SSH_HOST_RSA_PRIVATE_B64=$(base64 -w0 "$TMP_KEY_RSA")
  SSH_HOST_RSA_PUBLIC_B64=$(base64 -w0 "$TMP_KEY_RSA.pub")
  rm -f "$TMP_KEY_RSA" "$TMP_KEY_RSA.pub"
  echo $SSH_HOST_RSA_PRIVATE_B64 > "$RESOURCES_DIR/ssh_host_rsa_key.b64"
  echo $SSH_HOST_RSA_PUBLIC_B64 > "$RESOURCES_DIR/ssh_host_rsa_key.pub.b64"
fi

# 5. Get organization and activation key..

# 5.1 Organization
ORGANIZATION_FILE="/var/passwd/redhat/organization"
ORGANIZATION=""
if [ -f "$ORGANIZATION_FILE" ]; then
  ORGANIZATION=$(cat "$ORGANIZATION_FILE" | base64 -d | tr -d '[:space:]')
  echo " -> Organization ID got from $ORGANIZATION_FILE"
fi

if [ -z "$ORGANIZATION" ]; then
  read -p "Type Red Hat Organization ID: " ORGANIZATION
  echo
fi

# 5.2 Activation Key
ACTIVATION_KEY_FILE="/var/passwd/redhat/activation_key"
ACTIVATION_KEY=""
if [ -f "$ACTIVATION_KEY_FILE" ]; then
  ACTIVATION_KEY=$(cat "$ACTIVATION_KEY_FILE" | base64 -d | tr -d '[:space:]')
  echo " -> Activation Key got from $ACTIVATION_KEY_FILE"
fi

if [ -z "$ACTIVATION_KEY" ]; then
  read -p "Type Red Hat Activation Key: " ACTIVATION_KEY
fi

# 6. Generate authorized_keys..
AUTHORIZED_SSH_KEYS_FILE="$RESOURCES_DIR/authorized_keys"
AUTHORIZED_SSH_KEYS=""
if [ -f "$AUTHORIZED_SSH_KEYS_FILE" ]; then
  AUTHORIZED_SSH_KEYS=$(cat "$AUTHORIZED_SSH_KEYS_FILE")
  echo " -> Authorized keys got from $AUTHORIZED_SSH_KEYS_FILE"
fi

if [ -z "$AUTHORIZED_SSH_KEYS" ]; then
  echo "Typ authorized_keys.."
  echo "Enter each key followed by [ENTER]. When done, just press [ENTER] on an empty line."
  AUTHORIZED_SSH_KEYS=""
  while true; do
    read -p "SSH Authorized Key: " SSH_KEY
    if [ -z "$SSH_KEY" ]; then
      break
    fi
    AUTHORIZED_SSH_KEYS+="$SSH_KEY"$'\n'
  done
  echo "$AUTHORIZED_SSH_KEYS" > "$AUTHORIZED_SSH_KEYS_FILE"
fi
AUTHORIZED_SSH_KEYS_B64=$(echo -n "$AUTHORIZED_SSH_KEYS" | base64 -w0)

# Create final anaconda.ks.cfg file..
sed -e "s|{{ROOT_PASSWORD_HASH}}|$ROOT_PASSWORD_HASH|g" \
    -e "s|{{USER_NAME}}|$USER_NAME|g" \
    -e "s|{{USER_PASSWORD_HASH}}|$USER_PASSWORD_HASH|g" \
    -e "s|{{GROUP_NAME}}|$GROUP_NAME|g" \
    -e "s|{{USER_ID}}|$USER_ID|g" \
    -e "s|{{GROUP_ID}}|$GROUP_ID|g" \
    -e "s|{{AUTHORIZED_SSH_KEYS_B64}}|$AUTHORIZED_SSH_KEYS_B64|g" \
    -e "s|{{SSH_HOST_ECDSA_PRIVATE_B64}}|$SSH_HOST_ECDSA_PRIVATE_B64|g" \
    -e "s|{{SSH_HOST_ECDSA_PUBLIC_B64}}|$SSH_HOST_ECDSA_PUBLIC_B64|g" \
    -e "s|{{SSH_HOST_ED25519_PRIVATE_B64}}|$SSH_HOST_ED25519_PRIVATE_B64|g" \
    -e "s|{{SSH_HOST_ED25519_PUBLIC_B64}}|$SSH_HOST_ED25519_PUBLIC_B64|g" \
    -e "s|{{SSH_HOST_RSA_PRIVATE_B64}}|$SSH_HOST_RSA_PRIVATE_B64|g" \
    -e "s|{{SSH_HOST_RSA_PUBLIC_B64}}|$SSH_HOST_RSA_PUBLIC_B64|g" \
    -e "s|{{ORGANIZATION}}|$ORGANIZATION|g" \
    -e "s|{{ACTIVATION_KEY}}|$ACTIVATION_KEY|g" \
    -e "s|{{VM_NAME}}|$VM_NAME|g" \
  "$ANACONDA_KS_CFG_SKELETON_FILE" > "$RESOURCES_DIR/anaconda-ks.cfg"

# Build update-ks.cfg when the build script is present..
echo " -> Checking for update-ks.cfg build script.."
BUILD_KS_SCRIPT="$RESOURCES_DIR/bin/build-update-ks.cfg.sh"
if [ -f "$BUILD_KS_SCRIPT" ]; then
  echo " -> Building update-ks.cfg.. ($BUILD_KS_SCRIPT)"
  bash "$BUILD_KS_SCRIPT"
fi


#
# update-ks.cfg.sh
#
# --- CONFIGURATION ---
TARGET_FILE="$RESOURCES_DIR/anaconda-ks.cfg"
SOURCE_FILE="$RESOURCES_DIR/update-ks.cfg"

# Improved marker names
MARKER_START="# === BEGIN-UPDATE-KS.CFG ==="
MARKER_END="# === END-UPDATE-KS.CFG ==="

# Helper temporary file
TEMP_FILE="${TARGET_FILE}.tmp"

# --- CHECKS ---
if [ ! -f "$TARGET_FILE" ]; then
    echo "ERROR: Target file '$TARGET_FILE' does not exist!"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "ERROR: Source file '$SOURCE_FILE' does not exist!"
    exit 1
fi

# Verify if markers are actually present in the file
if ! grep -q "$MARKER_START" "$TARGET_FILE" || ! grep -q "$MARKER_END" "$TARGET_FILE"; then
    echo "ERROR: Missing start or end marker in file '$TARGET_FILE'."
    exit 1
fi

echo "Updating section in $TARGET_FILE..."

# --- SED MAGIC (Clean version) ---
# 1. /START/,/END/ {...}  -> Work only inside the block between markers
# 2. /START/r FILE        -> At start marker, read file (inserts below it)
# 3. /START/b             -> Is it the start marker? SKIP (so it is not deleted)
# 4. /END/b               -> Is it the end marker? SKIP (so it is not deleted)
# 5. d                    -> If you reached here (you are in the middle), DELETE the line.

sed -i "/$MARKER_START/,/$MARKER_END/{
    /$MARKER_START/r $SOURCE_FILE
    /$MARKER_START/b
    /$MARKER_END/b
    d
}" "$TARGET_FILE"
