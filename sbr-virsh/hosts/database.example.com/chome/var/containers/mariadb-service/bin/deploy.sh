#!/bin/bash
set -euo pipefail

#
BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_FOLDER="$(dirname "$SCRIPT_PATH")"
PARENT_FOLDER="$(dirname "$SCRIPT_FOLDER")"
FOLDER_NAME="$(basename "$PARENT_FOLDER")"

# Name of the container..
CONTAINER_NAME="$FOLDER_NAME"

# Get MariaDB root password..
MARIADB_ROOT_PASSWORD=$(base64 -d /var/containers/$CONTAINER_NAME/.MARIADB_ROOT_PASSWORD | tr -d '\n')

echo "➡️ Creating required directories..."
sudo mkdir -p /var/containers/$CONTAINER_NAME/data
sudo mkdir -p /etc/containers/systemd

# --- 2. CREATE QUADLET ---
echo "➡️ Generatomg Quadlet for MariaDB..."
sudo tee /etc/containers/systemd/mariadb.container > /dev/null <<EOF
[Unit]
Description=MariaDB Database Container
After=network-online.target

[Container]
Image=docker.io/library/mariadb:latest
ContainerName=mariadb-service

# 
Environment=MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}

# Port mapping..
PublishPort=3306:3306

# Volume mapping pro perzistentní data..
Volume=/var/containers/$CONTAINER_NAME/data:/var/lib/mysql:Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# --- 3. Reload systemd and start the container ---
echo "➡️ Reloading systemd..."
sudo systemctl daemon-reload

# --- 4. Start the container service ---
echo "➡️ Starting MariaDB container service..."
sudo systemctl restart mariadb.service

# --- 5. Check status ---
echo "➡️ MariaDB container deployment complete. Current status:"
sudo systemctl status mariadb.service --no-pager