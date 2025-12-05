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

# Get LDAP password from security database..
export LDAP_PASSWORD=$(cat /var/passwd/$VM_NAME/ldap_root.passwd)"

# Perform LDAP search..
ldapsearch -x -H ldap://ldap.local.nutius.com     -D "cn=Manager,dc=nutius,dc=com" -w "$LDAP_PASSWORD"     -b "dc=nutius,dc=com"     "(objectclass=*)"
