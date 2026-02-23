#!/bin/bash

# Get the directory where the script is located..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run ansible-playbook with a path relative to the script location..
ansible-playbook -i "${SCRIPT_DIR}/inventory.ini" "${SCRIPT_DIR}/playbooks/prometheus.yaml"
