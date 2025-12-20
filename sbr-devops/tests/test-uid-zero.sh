#!/bin/bash
# DESCRIPTION: Ensure no user other than 'root' has UID 0

# Find all users with UID 0 except 'root'
EXTRA_ROOTS=$(awk -F: '($3 == 0) && ($1 != "root") { print $1 }' /etc/passwd)

# If no such users are found, exit with success..
if [ -z "$EXTRA_ROOTS" ]; then
    exit 0
fi

# ..otherwise, exit with failure.
exit 1