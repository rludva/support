#!/bin/bash

# DESCRIPTION: Checks if SELinux is set to Enforcing mode
# TARGET: RHEL 10 Security Policy

# Check SELinux mode..
if [[ $(getenforce) == "Enforcing" ]]; then
    exit 0
else
    exit 1
fi
