#!/bin/bash
set -euo pipefail

# --- 1. SETUP PATHS & VARIABLES ---
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

CONTAINER_NAME="$FOLDER_NAME"
SECRET_DIR="/var/containers/${CONTAINER_NAME}"

# Using the new service domain (port 443 via HAProxy)
REGISTRY_URL="registry.service.example.com"

# --- 2. Check Arguments ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <repository_name> <tag>"
    echo "Example: $0 rludva/rundeck latest"
    exit 1
fi

REPO=$1
TAG=$2

# --- 3. LOAD SECRETS FROM FILES ---
echo "➡️ Loading credentials from ${SECRET_DIR}..."

DEFAULT_USER=""
DEFAULT_PASSWORD=""

if [ -f "${SECRET_DIR}/.REGISTRY_USER_NAME" ]; then
    DEFAULT_USER=$(sudo cat "${SECRET_DIR}/.REGISTRY_USER_NAME" | base64 -d | tr -d '\n')
fi

if [ -f "${SECRET_DIR}/.REGISTRY_USER_PASSWORD" ]; then
    DEFAULT_PASSWORD=$(sudo cat "${SECRET_DIR}/.REGISTRY_USER_PASSWORD" | base64 -d | tr -d '\n')
fi

# --- 4. Interactive Authentication ---
echo "=== Registry Authentication ==="
read -p "Enter Registry User [${DEFAULT_USER}]: " INPUT_USER
USER_NAME="${INPUT_USER:-$DEFAULT_USER}"

read -s -p "Enter Registry User Password [${DEFAULT_PASSWORD}]: " INPUT_PASSWORD
echo "" 
USER_PASSWORD="${INPUT_PASSWORD:-$DEFAULT_PASSWORD}"

if [ -z "$USER_NAME" ] || [ -z "$USER_PASSWORD" ]; then
    echo "❌ Error: Credentials cannot be empty."
    exit 1
fi

# --- 5. Delete Image Process ---
echo ""
echo "➡️ Targeted image: ${REGISTRY_URL}/${REPO}:${TAG}"

# Step A: Fetch the Docker-Content-Digest
# We must send the specific Accept header to get the digest in the response headers
echo "➡️ Fetching image digest..."
set +e
HEADERS=$(curl -s -k -I \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  -u "${USER_NAME}:${USER_PASSWORD}" \
  "https://${REGISTRY_URL}/v2/${REPO}/manifests/${TAG}")
set -e

# Extract the digest from headers
DIGEST=$(echo "$HEADERS" | grep -i Docker-Content-Digest | awk '{print $2}' | tr -d $'\r' | tr -d '\n')

if [ -z "$DIGEST" ]; then
    echo "❌ Error: Could not find digest for ${REPO}:${TAG}. Is the image/tag correct?"
    echo "Check if REGISTRY_STORAGE_DELETE_ENABLED=true is set in the container."
    exit 1
fi

echo "➡️ Found Digest: $DIGEST"

# Step B: Perform the DELETE request
echo "➡️ Sending DELETE request..."
set +e
HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" \
  -X DELETE \
  -u "${USER_NAME}:${USER_PASSWORD}" \
  "https://${REGISTRY_URL}/v2/${REPO}/manifests/${DIGEST}")
set -e

if [ "$HTTP_CODE" -eq 202 ]; then
    echo "✅ Success: Manifest for ${REPO}:${TAG} has been deleted."
    echo ""
    echo "⚠️  IMPORTANT: The disk space has NOT been freed yet."
    echo "Run the following command on the registry server to trigger Garbage Collection:"
    echo "----------------------------------------------------------------------------"
    echo "sudo podman exec cluster-registry bin/registry garbage-collect /etc/docker/registry/config.yml"
    echo "----------------------------------------------------------------------------"
else
    echo "❌ Error: Delete failed with HTTP code $HTTP_CODE."
    if [ "$HTTP_CODE" -eq 405 ]; then
        echo "Reason: Method Not Allowed. Make sure 'REGISTRY_STORAGE_DELETE_ENABLED=true' is set."
    fi
    exit 1
fi