#!/bin/bash
# DESCRIPTION: Check for accounts with empty passwords in /etc/shadow

# If any users with empty passwords are found, they will be listed in the USERS_WITHOUT_PASS variable
USERS_WITHOUT_PASS=$(awk -F: '$2 == "" {print $1}' /etc/shadow)

# If the variable is empty, everything is fine (exit 0)
if [ -z "$USERS_WITHOUT_PASS" ]; then
    exit 0
fi

# If there are users with empty passwords, exit with code 1
exit 1