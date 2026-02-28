#!/bin/bash
set -euo pipefail

# --- 1. SETUP PATHS & VARIABLES ---
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Set container name..
CONTAINER_NAME="$FOLDER_NAME"

REGISTRY_HOST="registry.redhat.io"
IMAGE="offline-knowledge-portal/rhokp-rhel9"
TAG="latest"

# --- 2. LOAD SECRETS FROM FILES ---
echo "➡️ Loading secrets from hidden files..."

# Ensure the secret files exist before trying to read them
SECRET_DIR="/var/containers/${CONTAINER_NAME}"

for SECRET_FILE in ".RHOKP_ACCESS_KEY" ".REGISTRY_USER" ".REGISTRY_PASS"; do
    if [ ! -f "${SECRET_DIR}/${SECRET_FILE}" ]; then
        echo "❌ Error: Secret file ${SECRET_DIR}/${SECRET_FILE} is missing!"
        exit 1
    fi
done

# Read the values and strip any trailing newlines
RHOKP_ACCESS_KEY=$(base64 -d "${SECRET_DIR}/.RHOKP_ACCESS_KEY" | tr -d '\n')
REGISTRY_USER=$(base64 -d  "${SECRET_DIR}/.REGISTRY_USER" | tr -d '\n')
REGISTRY_PASS=$(base64 -d "${SECRET_DIR}/.REGISTRY_PASS" | tr -d '\n')

# --- 3. LOGIN & DIRECTORIES ---
echo "➡️ Logging into Red Hat Registry..."
sudo podman login --username "${REGISTRY_USER}" --password "${REGISTRY_PASS}" "${REGISTRY_HOST}"

echo "➡️ Creating required directories for certificates..."
sudo mkdir -p /var/containers/${CONTAINER_NAME}/httpd-ssl/certs
sudo mkdir -p /var/containers/${CONTAINER_NAME}/httpd-ssl/private
sudo mkdir -p /etc/containers/systemd

echo "➡️ Copying SSL certificates..."
sudo cp /var/certificates/${CONTAINER_NAME}/fullchain.pem /var/containers/${CONTAINER_NAME}/httpd-ssl/certs/server.pem
sudo cp /var/certificates/${CONTAINER_NAME}/privkey.pem /var/containers/${CONTAINER_NAME}/httpd-ssl/private/server.pem

sudo chmod 640 /var/containers/${CONTAINER_NAME}/httpd-ssl/certs/server.pem
sudo chmod 640 /var/containers/${CONTAINER_NAME}/httpd-ssl/private/server.pem

# --- 4. CREATE QUADLET ---
echo "➡️ Generating Quadlet for ${CONTAINER_NAME}..."
sudo tee /etc/containers/systemd/${CONTAINER_NAME}.container > /dev/null <<EOF
[Unit]
Description=Red Hat Off-line Knowledge Portal (RHOKP)
After=network-online.target

[Container]
Image=${REGISTRY_HOST}/${IMAGE}:${TAG}
ContainerName=${CONTAINER_NAME}

# Read the access key securely from our script variable
Environment=ACCESS_KEY=${RHOKP_ACCESS_KEY}

# Port mapping
PublishPort=8080:8080
PublishPort=8443:8443

# Volume mapping for SSL certificates
Volume=/var/containers/${CONTAINER_NAME}/httpd-ssl:/opt/app-root/httpd-ssl:Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# --- 5. RELOAD AND START SERVICE ---
echo "➡️ Reloading systemd..."
sudo systemctl daemon-reload

echo "➡️ Starting ${CONTAINER_NAME} container service..."
sudo systemctl restart ${CONTAINER_NAME}.service

echo "✅ Deployment complete! Current status:"
sudo systemctl status ${CONTAINER_NAME}.service --no-pager