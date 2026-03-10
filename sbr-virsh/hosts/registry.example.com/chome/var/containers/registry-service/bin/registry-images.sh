#!/bin/bash
set -euo pipefail

# --- 1. SETUP PATHS & VARIABLES ---
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

CONTAINER_NAME="$FOLDER_NAME"
SECRET_DIR="/var/containers/${CONTAINER_NAME}"

REGISTRY_URL="registry.service.example.com"

# --- 2. Check Prerequisites ---
if ! command -v jq &> /dev/null; then
    echo "❌ Error: 'jq' command is not installed. Please install it (e.g., sudo dnf install -y jq)."
    exit 1
fi

# --- 3. LOAD SECRETS FROM FILES ---
echo "➡️ Loading secrets from hidden files in ${SECRET_DIR}..."

DEFAULT_USER=""
DEFAULT_PASSWORD=""

# Check for User Name file
if [ -f "${SECRET_DIR}/.REGISTRY_USER_NAME" ]; then
    DEFAULT_USER=$(sudo cat "${SECRET_DIR}/.REGISTRY_USER_NAME" | base64 -d | tr -d '\n')
else
    echo "⚠️ Warning: Secret file ${SECRET_DIR}/.REGISTRY_USER_NAME is missing."
fi

# Check for Password file (Note: Your deploy script used PASSWD, we stick to PASSWORD for consistency with your Ansible)
if [ -f "${SECRET_DIR}/.REGISTRY_USER_PASSWORD" ]; then
    DEFAULT_PASSWORD=$(sudo cat "${SECRET_DIR}/.REGISTRY_USER_PASSWORD" | base64 -d | tr -d '\n')
else
    echo "⚠️ Warning: Secret file ${SECRET_DIR}/.REGISTRY_USER_PASSWORD is missing."
fi


# --- 4. Interactive Prompt ---
echo ""
echo "=== Registry Authentication ==="

# Prompt for Username
read -p "Enter Registry User [${DEFAULT_USER}]: " INPUT_USER
USER_NAME="${INPUT_USER:-$DEFAULT_USER}"

# Prompt for Password (-s hides typing)
read -s -p "Enter Registry User Password [${DEFAULT_PASSWORD}]: " INPUT_PASSWORD
echo "" # Vytiskne nový řádek po skrytém zadávání hesla
USER_PASSWORD="${INPUT_PASSWORD:-$DEFAULT_PASSWORD}"

# Validation
if [ -z "$USER_NAME" ] || [ -z "$USER_PASSWORD" ]; then
    echo "❌ Error: Credentials cannot be empty. Exiting."
    exit 1
fi

# --- 5. Fetch Images ---
echo ""
echo "=== Fetching images from https://$REGISTRY_URL ==="
echo "---------------------------------------------------"

# Get the list of repositories (images)
# set +e is used here because a failed curl (e.g. wrong password) shouldn't immediately crash the script due to 'set -e'
set +e
REPOS_JSON=$(curl -s -k -u "${USER_NAME}:${USER_PASSWORD}" "https://${REGISTRY_URL}/v2/_catalog")
CURL_EXIT=$?
set -e

if [ $CURL_EXIT -ne 0 ]; then
     echo "❌ Error: curl command failed to reach the registry API."
     exit 1
fi

# Check if authentication was successful
if echo "$REPOS_JSON" | grep -q "UNAUTHORIZED" || echo "$REPOS_JSON" | grep -q "UNSUPPORTED"; then
    echo "❌ Error: Authentication failed or API endpoint unsupported! Please check your credentials."
    exit 1
fi

REPOS=$(echo "$REPOS_JSON" | jq -r '.repositories[]?')

if [ -z "$REPOS" ]; then
    echo "ℹ️ No images found in the registry."
    exit 0
fi

# Loop through each repository and get its tags
for REPO in $REPOS; do
    TAGS=$(curl -s -k -u "${USER_NAME}:${USER_PASSWORD}" "https://${REGISTRY_URL}/v2/${REPO}/tags/list" | jq -r '.tags[]?')
    
    if [ -z "$TAGS" ] || [ "$TAGS" == "null" ]; then
        echo "${REGISTRY_URL}/${REPO}  -->  <no tags>"
    else
        for TAG in $TAGS; do
            echo "${REGISTRY_URL}/${REPO}:${TAG}"
        done
    fi
done

echo "---------------------------------------------------"
echo "✅ Done."