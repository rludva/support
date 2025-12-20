#!/bin/bash

# DESCRIPTION: Verifies that PasswordAuthentication is disabled in sshd
# TARGET: RHEL 10 Security Policy

# Get effective config
SETTING=$(sshd -T 2>/dev/null | grep -i "^passwordauthentication" | awk '{print $2}')

if [ "$SETTING" == "no" ]; then
    exit 0
else
    exit 1
fi
