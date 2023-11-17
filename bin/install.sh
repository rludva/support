#!/bin/bash

#
MY_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Destination folder..
DESTINATION="/usr/local/bin"

# Copy script dependencies..
cp -v $MY_PATH/tools/script_dependencies.sh $DESTINATION

# Extended CRC Stuff..
echo "Copy extended CRC commands to $DESTINATION"
cp -v $MY_PATH/sbr-crc/crc-cleanup $DESTINATION
cp -v $MY_PATH/sbr-crc/crc-dashboard $DESTINATION
cp -v $MY_PATH/sbr-crc/crc-htpasswd  $DESTINATION
cp -v $MY_PATH/sbr-crc/crc-login  $DESTINATION
cp -v $MY_PATH/sbr-crc/crc-passwd  $DESTINATION
cp -v $MY_PATH/sbr-crc/crc-ssh  $DESTINATION
cp -v $MY_PATH/sbr-crc/crc-start  $DESTINATION

# Extended OpenShift Logging Stuff..
echo
echo "Copy extended OpenShift Logging commnads to $DESTINATION"
cp -v $MY_PATH/sbr-shift-logging/bin/logging-dashboard.sh $DESTINATION

# Extended CodeReady Workspaces Stuff..
echo
echo "Copy extended CodeReady Workspaces commands to $DESTINATION"
cp -v $MY_PATH/sbr-crw/bin/crw-deploy $DESTINATION
cp -v $MY_PATH/sbr-crw/bin/crw-get-ca $DESTINATION

echo
echo "Copy o-must-gather extented tools.."
cp -v $MY_PATH/tools/omc-init $DESTINATION

echo
echo "Copy oc-package tool.."
cp -v $MY_PATH/sbr-coreos/oc-package $DESTINATION
