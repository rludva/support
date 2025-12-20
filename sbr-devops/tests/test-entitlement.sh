#!/bin/bash
# DESCRIPTION: Check if the system is properly registered via Subscription Manager

# The 'subscription-manager status' command returns exit code 0 only if the system is registered
# and has valid/current subscriptions (Overall Status: Current).
subscription-manager status &>/dev/null

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    exit 0
else
    exit 1
fi