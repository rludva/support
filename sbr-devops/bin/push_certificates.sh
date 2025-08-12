#!/bin/bash

# This script is used to push certificates to a OpenShift cluster
# from a bastion host. It retrieves certificates from the bastion host
# and updates the corresponding secrets in the OpenShift cluster.
MANAGEMENT_ACCOUNT="$USER"
BASTION_HOST="bastion.example.com"
PROCESS_HOST="$HOSTNAME"

# 1. console-tls
process_certificate() {
  SECRET_NAME="$1"
  DOMAIN="$2"
  NAMESPACE="$3"
  
  echo "Processing certificate: $SECRET_NAME"
  TMP_FOLDER=$(mktemp -d /tmp/certs_XXXXXX)
  
  echo "TMP_FOLDER: $TMP_FOLDER"
  
  
  ssh $MANAGEMENT_ACCOUNT@$BASTION_HOST "sudo bash -c '
    cd /etc/letsencrypt/live/$DOMAIN
    scp *.pem $MANAGEMENT_ACCOUNT@$PROCESS_HOST:$TMP_FOLDER
  '"
  
  ls -l "$TMP_FOLDER"
  

  # Pokud secret neexistuje, rovnou skončíme (vrátíme 0 a pokračujeme)
  oc get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || {
    echo "Secret $SECRET_NAME not found, skipping delete."
    exit 1
  }  

  # Pokud delete selže, ukončíme skript s chybou
  oc delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found || {
    echo "Error: failed to delete secret $SECRET_NAME"
    exit 1
  }

  openssl x509 -in "$TMP_FOLDER/cert.pem" -text -noout -dates

  oc create secret tls $SECRET_NAME --cert="$TMP_FOLDER/fullchain.pem" --key="$TMP_FOLDER/privkey.pem" -n $NAMESPACE
  
  rm -rf "$TMP_FOLDER"
}

#
# Process certificates for different clusters..
# (replace with your cluster name and domain)
CLUSTER_NAME="sanpuru"
CLUSTE_DOMAIN="example.com"
process_certificate "console-tls" "console-openshift-console.apps.$CLUSTER_NAME.$CLUSTER_DOMAIN" "openshift-config"
process_certificate "oauth-tls" "oauth-openshift.apps.$CLUSTER_NAME.$CLUSTER_DOMAIN"  "openshift-config"
process_certificate "apps-tls" "apps.$CLUSTER_NAME.$CLUSTER_DOMAIN" "openshift-ingress"

CLUSTER_NAME="mihon"
CLUSTE_DOMAIN="example.com"
process_certificate "console-tls" "console-openshift-console.apps.$CLUSTER_NAME.$CLUSTER_DOMAIN" "openshift-config"
process_certificate "oauth-tls" "oauth-openshift.apps.$CLUSTER_NAME.$CLUSTER_DOMAIN"  "openshift-config"
process_certificate "apps-tls" "apps.$CLUSTER_NAME.$CLUSTER_DOMAIN" "openshift-ingress"
