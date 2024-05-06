#!/bin/bash

# TODO:
# -----
# 1. Create selection box with common names and select the secret name from a menu
#    - app-tls, oauth-tls, console-tls, eclipse-tls, etc.
# 

# This script is used to generate information about TLS certificate stored in a secret.
# The argument is secret name and it is listed from the current namespace.

# The secret name
SECRET_NAME="$1"

tls=$(oc get secret $SECRET_NAME -o jsonpath='{.data.tls\.crt}')
decoded_tls=$(echo $tls | base64 -d)

echo "TLS certificate: $decoded_tls"
textinfo=$(echo "$decoded_tls" | openssl x509 -text)

echo "TLS certificate information: $textinfo"