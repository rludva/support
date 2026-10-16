# ServiceAccount Token for Ansible Automation Platform

## Context
Ansible Automation Platform (AAP) needs a token to authenticate to OpenShift.  The token from `Copy login command` in the OpenShift console belongs to a user and expires after 24 hours, so jobs in AAP start failing the next day.

This article shows how to create a dedicated ServiceAccount with a persistent token stored in a Secret.  This token does not expire.  It is valid until the Secret (or the ServiceAccount) is deleted.

## Prerequisites

- An OpenShift deployment
- An Ansible Automation Platform deployment
- Credentials for OpenShift with the `cluster-admin` role (to create the ClusterRoleBinding)
- The `oc` command

## Procedure

### Create the ServiceAccount and its token

1. Log in to OpenShift with your own user.

    ```bash
    $ oc login --token=sha256~<your-token> --server=https://api.cluster_name.example.com:6443
    ```

1. Create a dedicated ServiceAccount in the `default` namespace.

    ```bash
    $ oc create serviceaccount aap-sa -n default
    serviceaccount/aap-sa created
    ```

1. Create the persistent Secret for the ServiceAccount.  OpenShift fills in the token automatically because of the `kubernetes.io/service-account.name` annotation.

    ```bash
    $ cat <<EOF | oc apply -f -
    apiVersion: v1
    kind: Secret
    metadata:
      name: aap-sa-token
      namespace: default
      annotations:
        kubernetes.io/service-account.name: aap-sa
    type: kubernetes.io/service-account-token
    EOF
    secret/aap-sa-token created
    ```

1. Grant the required RBAC permissions (`cluster-admin`).

    ```bash
    $ oc create clusterrolebinding aap-sa-binding \
      --clusterrole=cluster-admin \
      --serviceaccount=default:aap-sa
    clusterrolebinding.rbac.authorization.k8s.io/aap-sa-binding created
    ```

    `cluster-admin` gives the ServiceAccount full access to the whole cluster.  If AAP only needs some namespaces, use a narrower role.

1. Extract and decode the bearer token.

    ```bash
    $ TOKEN=$(oc get secret aap-sa-token -n default -o jsonpath='{.data.token}' | base64 -d)
    $ echo "$TOKEN"
    ```

    If the output is empty, wait a few seconds until OpenShift fills in the Secret and run the commands again.

1. Verify the token works.

    ```bash
    $ oc --token="$TOKEN" whoami
    system:serviceaccount:default:aap-sa
    ```

    You can also call the API directly with the token, the same way AAP does.

    ```bash
    $ curl -k -H "Authorization: Bearer $TOKEN" $(oc whoami --show-server)/api
    {
      "kind": "APIVersions",
      "versions": [
        "v1"
      ],
      "serverAddressByClientCIDRs": [
        {
          "clientCIDR": "0.0.0.0/0",
          "serverAddress": "<api-server-ip>:6443"
        }
      ]
    }
    ```

    With an invalid token, the API returns `401 Unauthorized` instead.

    ```bash
    $ curl -k -H "Authorization: Bearer invalid" $(oc whoami --show-server)/api
    {
      "kind": "Status",
      "apiVersion": "v1",
      "metadata": {},
      "status": "Failure",
      "message": "Unauthorized",
      "reason": "Unauthorized",
      "code": 401
    }
    ```


### Use the token in AAP

1. In the AAP web UI, go to `Automation Execution` → `Infrastructure` → `Credentials` and click `Create credential`.

    In AAP 2.4 and older, the path is `Resources` → `Credentials` → `Add`.

1. Fill in the general fields:

    - **Name**: e.g. `OpenShift cluster_name (aap-sa)`
    - **Organization**: your organization (default is `Default`)
    - **Credential type**: `OpenShift or Kubernetes API Bearer Token`

1. Fill in the type details:

    - **OpenShift or Kubernetes API Endpoint**: `https://api.cluster_name.example.com:6443`
    - **API authentication bearer token**: the value of `$TOKEN`
    - **Verify SSL**: check it to verify the API certificate.  Leave it unchecked if the cluster uses an internal or private CA.
    - **Certificate Authority data**: optional, the CA certificate including the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines

1. Click `Create credential`.

1. If you need the CA certificate, get it from the same Secret.

    ```bash
    $ oc get secret aap-sa-token -n default -o jsonpath='{.data.ca\.crt}' | base64 -d
    ```

    FIXME: Check whether `ca.crt` is enough for the API certificate of the cluster, or whether the ingress CA is needed too.

This credential type is used mainly for container groups.  A container group runs AAP jobs as pods in the OpenShift cluster.  Create it in `Automation Execution` → `Infrastructure` → `Instance Groups` → `Create group` → `Create container group` and select this credential.

FIXME: Describe how the credential is used in our setup (container group, or playbooks with the `kubernetes.core` collection).

## Troubleshooting

### Expired token

```
$ oc get pods
E0414 13:25:44.427184  607698 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: the server has asked for the client to provide credentials"
```

This is the error you get with a normal user token after 24 hours.  The ServiceAccount token from this article does not expire.  If you see this error in AAP with the ServiceAccount token, check that the Secret `aap-sa-token` still exists in the `default` namespace.

### Revoking the token

To revoke the token (e.g. when it leaked), delete the Secret and create it again.  The new Secret gets a new token, so update the credential in AAP.

```bash
$ oc delete secret aap-sa-token -n default
```

To remove the whole setup:

```bash
$ oc delete clusterrolebinding aap-sa-binding
$ oc delete serviceaccount aap-sa -n default
```

## Additional Information
Provide links or references to more information that could be useful:
- [Using service accounts in applications (OKD)](https://docs.okd.io/latest/authentication/using-service-accounts-in-applications.html)
- [Credentials (AWX)](https://ansible.readthedocs.io/projects/awx/en/latest/userguide/credentials.html)
- [Long-lived API token for a ServiceAccount (Kubernetes)](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#manually-create-an-api-token-for-a-serviceaccount)

## Conclusion

AAP now authenticates to OpenShift with the `aap-sa` ServiceAccount token, which does not expire after 24 hours.  Keep the token secret.  With `cluster-admin`, anyone who has the token has full control of the cluster.
