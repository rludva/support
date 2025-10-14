#!/bin/bash
# operator-cleanup.sh
# Usage: ./operator-cleanup.sh <operator_name>
#        ./operator-cleanup.sh openshift-gitops-operator.openshift-gitops-operator

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <operator_name>"
    exit 1
fi

OPERATOR="$1"

echo "=== Cleaning operator: $OPERATOR ==="

# 1. Get all CRDs that are managed by the operator..
crds=$(oc get operator "$OPERATOR" -o yaml \
       | yq -r '.status.components.refs[] | select(.kind=="CustomResourceDefinition") | .name')

if [ -z "$crds" ]; then
  echo "No CRDs found for operator $OPERATOR"
  exit 0
fi

# 2. Remove all instances of these CRDs..
for crd in $crds; do
  echo "=== Deleting instances of $crd ==="
  instances=$(oc get "$crd" -A -o name 2>/dev/null || true)
  if [ -n "$instances" ]; then
      echo "$instances" | xargs -r oc delete
  else
      echo "No instances found for $crd"
  fi
done

# 3. Remove finalizers from the CRDs to allow deletion..
for crd in $crds; do
  echo "=== Removing finalizers for $crd ==="
  oc patch crd "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
done

# 4. Delete the CRDs themselves..
for crd in $crds; do
  echo "=== Deleting CRD $crd ==="
  oc delete crd "$crd" || true
done
