#!/bin/bash

# Default values
REGISTRY_NAME="mirror-registry"
REGISTRY_HOST="localhost"
REGISTRY_PORT="5000"
STORAGE="/opt/registry/$REGISTRY_NAME"

USER_NAME=""
USER_PASSWD=""

source registry-data.sh

sudo yum install -y podman httpd-tools

sudo firewall-cmd --add-port=$REGISTRY_PORT/tcp --zone=internal --permanent
sudo firewall-cmd --add-port=$REGISTRY_PORT/tcp --zone=public   --permanent
sudo firewall-cmd --reload

sudo mkdir -p $STORAGE/{auth,certs,data}

# Non CA Certificate is not usable!
# cd $STORAGE/certs && openssl req -newkey rsa:4096 -nodes -sha256 -keyout $REGISTRY_NAME.key -x509 -days 365 -out $REGISTRY_NAME.crt
# cp $STORAGE/certs/$REGISTRY_NAME.crt /etc/pki/ca-trust/source/anchors/

## Jen jednou spustit a když je to v nastavení clusteru tak už se nesmí změnit jinak to cluster nebude znát..
if [ ! -e "$STORAGE/certs/$REGISTRY_NAME-ca.key" ]; then
  echo "Generating certificates.."
	echo ""
  sudo openssl genrsa -out $STORAGE/certs/$REGISTRY_NAME-ca.key 2048
  sudo openssl req -x509 -new -key $STORAGE/certs/$REGISTRY_NAME-ca.key -out $STORAGE/certs/$REGISTRY_NAME-ca.crt -days 1460 -subj "/C=CZ/ST=CZ/L=test/O=Nutius Ltd/OU=Nutius Security Department/CN=security.nutius.com"
  sudo openssl genrsa -out $STORAGE/certs/$REGISTRY_NAME.key 2048
  sudo openssl req -new -key $STORAGE/certs/$REGISTRY_NAME.key -out $STORAGE/certs/$REGISTRY_NAME.csr -subj "/C=CZ/ST=CZ/L=test/O=Nutius Ltd/OU=test/CN=$REGISTRY_HOST"
  sudo openssl x509 -req -in $STORAGE/certs/$REGISTRY_NAME.csr -CA $STORAGE/certs/$REGISTRY_NAME-ca.crt -CAkey $STORAGE/certs/$REGISTRY_NAME-ca.key -CAcreateserial -out $STORAGE/certs/$REGISTRY_NAME.crt -days 365
fi

sudo cp $STORAGE/certs/$REGISTRY_NAME.crt /etc/pki/ca-trust/source/anchors/
sudo cp $STORAGE/certs/$REGISTRY_NAME-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
#
# Nevím tady jestli se musí i $REGISTRY_NAME-ca kopírovat do složky s důvěryhodnými certifikáty tady..
#

sudo htpasswd -bBc $STORAGE/auth/htpasswd $USER_NAME $USER_PASSWD

sudo podman run --name $REGISTRY_NAME -p $REGISTRY_PORT:5000 \
     -v $STORAGE/data:/var/lib/registry:z \
     -v $STORAGE/certs:/certs:z \
     -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_NAME.crt \
     -e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_NAME.key \
     -it \
     --rm \
     docker.io/library/registry:2

exit		 

# Aditional parameteters for podman run that are not used..
     -v $STORAGE/auth:/auth:z \
     -e "REGISTRY_AUTH=htpasswd" \
     -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
     -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
