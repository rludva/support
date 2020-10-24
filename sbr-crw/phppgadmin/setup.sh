#!/usr/bin/bash

USER=$(oc get secret/che-identity-secret -n openshift-workspaces -ojsonpath='{.data.user}' | base64 -d)
PASSWORD=$(oc get secret/che-identity-secret -n openshift-workspaces -ojsonpath='{.data.password}' | base64 -d)
echo "user: $USER"
echo "password: $PASSWORD"

oc create -f ./phppgadmin_pod.yaml
oc create -f ./phppgadmin_service.yaml
oc expose service phppgadmin

DBHOST=$(oc get pod -l component=postgres -ojsonpath='{..podIP}')
oc exec phppgadmin -- sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = '';/\$conf\['servers'\]\[0\]\['host'\] = '$DBHOST';/g" ./conf/config.inc.php
oc exec phppgadmin -- grep "$DBHOST" ./conf/config.inc.php
