#!/bin/bash
set -euo pipefail

#
VM_NAME="${1:?Usage: $0 <hostname>}"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
HOSTDIR="$BASEDIR/hosts/$VM_NAME"
RESOURCES_DIR="$HOSTDIR"

if [[ ! -d "$HOSTDIR" ]]; then
    echo "Host directory not found: $HOSTDIR"
    exit 1
fi

# 1. Type the root password..
read -s -p "Type root password: " ROOT_PASSWORD
echo

read -p "Type user name: " USER_NAME
echo

read -s -p "Type user password: " USER_PASSWORD
echo

read -p "User ID (leave empty for default): " USER_ID
echo

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

# Create final anaconta.ks.cfg file..
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
  "$RESOURCES_DIR/anaconda-ks.cfg.skel" > "$RESOURCES_DIR/anaconda-ks.cfg"

# Build update-ks.cfg when the build script is present..
echo " -> Checking for update-ks.cfg build script.."
BUILD_KS_SCRIPT="$RESOURCES_DIR/bin/build-update-ks.cfg.sh"
if [ -f "$BUILD_KS_SCRIPT" ]; then
  echo " -> Building update-ks.cfg.. ($BUILD_KS_SCRIPT)"
  bash "$BUILD_KS_SCRIPT"
fi

# Check if there is update-ks.cfg.sh script for this host..
echo " -> Checking for existence of update-ks.cfg.sh script.."
UPDATE_KS_SCRIPT="$RESOURCES_DIR/bin/update-ks.cfg.sh"
if [ -f "$UPDATE_KS_SCRIPT" ]; then
  echo " -> Injecting  update-ks.cfg to the anaconda-ks.cfg.. ($UPDATE_KS_SCRIPT)"
  bash "$UPDATE_KS_SCRIPT"
fi
