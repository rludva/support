#/bin/bash

# Resources:
# ----------
# [1] Checking etcd certificate expiry in OpenShift 4
#      https://access.redhat.com/solutions/7000968

echo -e "SECRET_NAME\tEXPIRATION_DATE"

oc get secret -n openshift-etcd -o json | jq -r '.items[] | select(( (.metadata.name|startswith("etcd-peer")) or (.metadata.name|startswith("etcd-serving")) ) and .type=="kubernetes.io/tls") | [.metadata.name,.data."tls.crt"] | @tsv' | \
while read -r name certificate; do
    echo -en "$name\t"
    echo "$certificate" | base64 -d | openssl x509 -noout -enddate | sed 's/notAfter=//g'
done | column -t -s $'\t'
