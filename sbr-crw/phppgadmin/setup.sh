#!/usr/bin/bash

USER=$(oc get secret/che-identity-secret -n openshift-workspaces -ojsonpath='{.data.user}' | base64 -d)
PASSWORD=$(oc get secret/che-identity-secret -n openshift-workspaces -ojsonpath='{.data.password}' | base64 -d)
echo "user: $USER"
echo "password: $PASSWORD"

PHPPGADMIN_POD_FILE="./phppgadmin_pod.yaml"
cat <<EOF > $PHPPGADMIN_POD_FILE
apiVersion: v1
kind: Pod
metadata:
  name: phppgadmin
  labels:
    app: phppgadmin
  namespace: openshift-workspaces
spec:
  containers:
  - env:
    image: dockage/phppgadmin
    name: phppgadmin
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
      protocol: TCP
EOF

PHPPGADMIN_SERVICE_FILE="./phppgadmin_pod.yaml"
cat <<EOF > $PHPPGADMIN_SERVICE_FILE
apiVersion: v1
kind: Service
metadata:
  labels:
    app: phppgadmin
  name: phppgadmin
  namespace: openshift-workspaces
spec:
  ports:
  - name: phppgadmin
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: phpphadmin
  sessionAffinity: None
  type: ClusterIP
EOF

oc create -f "$PHPPGADMIN_POD_FILE"
oc create -f "$PHPPGADMIN_SERVICE_FILE"
oc expose service phppgadmin

DBHOST=$(oc get pod -l component=postgres -ojsonpath='{..podIP}')
oc exec phppgadmin -- sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = '';/\$conf\['servers'\]\[0\]\['host'\] = '$DBHOST';/g" ./conf/config.inc.php
oc exec phppgadmin -- grep "$DBHOST" ./conf/config.inc.php
