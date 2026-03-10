#!/bin/bash
set -euo pipefail

echo "=== START: Registry Configuration ==="

# --- 1. SETUP PATHS & VARIABLES ---
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Set container name
CONTAINER_NAME="$FOLDER_NAME"

REGISTRY_NAME="cluster-registry"
REGISTRY_PORT="5000"
STORAGE="/var/registry/$REGISTRY_NAME"

# Path to Let's Encrypt certificates..
LETSENCRYPT_CERTIFICATES_FOLDER="/var/certificates/registry-service"

# --- 2. LOAD SECRETS FROM FILES ---
echo "➡️ Loading secrets from hidden files..."

SECRET_DIR="/var/containers/${CONTAINER_NAME}"

for SECRET_FILE in ".REGISTRY_USER_NAME" ".REGISTRY_USER_PASSWORD"; do
    if [ ! -f "${SECRET_DIR}/${SECRET_FILE}" ]; then
        echo "❌ Error: Secret file ${SECRET_DIR}/${SECRET_FILE} is missing!"
        exit 1
    fi
done

# Read the values and strip any trailing newlines (sjednoceno na _PASSWORD)
REGISTRY_USER_NAME=$(base64 -d "${SECRET_DIR}/.REGISTRY_USER_NAME" | tr -d '\n')
REGISTRY_USER_PASSWORD=$(base64 -d "${SECRET_DIR}/.REGISTRY_USER_PASSWORD" | tr -d '\n')

# --- 3. Package Installation ---
echo "Installing podman and httpd-tools..."
dnf install -y podman httpd-tools

# --- 4. Firewall Configuration ---
echo "Configuring firewall (online mode)..."

if firewall-cmd --query-port=${REGISTRY_PORT}/tcp >/dev/null 2>&1; then
    echo "Port ${REGISTRY_PORT}/tcp is already allowed. Skipping..."
else
    echo "Port ${REGISTRY_PORT}/tcp is not allowed. Adding to firewall rules..."
    firewall-cmd --add-port=${REGISTRY_PORT}/tcp --permanent
    firewall-cmd --reload
    echo "Firewall rules have been successfully updated."
fi

# --- 5. Directory Structure Preparation ---
echo "Creating directory structure in $STORAGE..."
mkdir -p $STORAGE/{auth,certs,data}

# --- 6. htpasswd Creation for Authentication ---
echo "Generating htpasswd file..."
htpasswd -bBc $STORAGE/auth/htpasswd $REGISTRY_USER_NAME $REGISTRY_USER_PASSWORD

# --- 7. Copy Let's Encrypt Certificates ---
echo "Copying Let's Encrypt certificates for the registry..."

if [ ! -f "${LETSENCRYPT_CERTIFICATES_FOLDER}/fullchain.pem" ] || [ ! -f "${LETSENCRYPT_CERTIFICATES_FOLDER}/privkey.pem" ]; then
    echo "❌ Error: Let's Encrypt certificates are missing in ${LETSENCRYPT_CERTIFICATES_FOLDER}!"
    exit 1
fi

# Registry needs fullchain.pem and privkey.pem, we copy them to the certs directory with appropriate names..
cp ${LETSENCRYPT_CERTIFICATES_FOLDER}/fullchain.pem $STORAGE/certs/${REGISTRY_NAME}.crt
cp ${LETSENCRYPT_CERTIFICATES_FOLDER}/privkey.pem $STORAGE/certs/${REGISTRY_NAME}.key

# Set appropriate permissions for the certificate files..
chmod 644 $STORAGE/certs/${REGISTRY_NAME}.crt
chmod 600 $STORAGE/certs/${REGISTRY_NAME}.key

# --- 8. Podman Quadlet Setup ---
echo "Creating Quadlet configuration for systemd..."

mkdir -p /etc/containers/systemd

cat > /etc/containers/systemd/${REGISTRY_NAME}.container <<EOF
[Unit]
Description=Disconnected OpenShift Registry
After=network-online.target

[Container]
Image=docker.io/library/registry:2
ContainerName=${REGISTRY_NAME}
PublishPort=${REGISTRY_PORT}:5000
Volume=${STORAGE}/data:/var/lib/registry:z
Volume=${STORAGE}/certs:/certs:z
Volume=${STORAGE}/auth:/auth:z
Environment=REGISTRY_STORAGE_DELETE_ENABLED=true
Environment=REGISTRY_HTTP_TLS_CERTIFICATE=/certs/${REGISTRY_NAME}.crt
Environment=REGISTRY_HTTP_TLS_KEY=/certs/${REGISTRY_NAME}.key
Environment=REGISTRY_AUTH=htpasswd
Environment=REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm
Environment=REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd

[Install]
WantedBy=multi-user.target
EOF

echo "=== Configuration Complete ==="