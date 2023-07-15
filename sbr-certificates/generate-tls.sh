#!/bin/bash

# Default values
TLS_CERTIFICATE="nutius.com"
HOST="app01"
STORAGE="./$TLS_CERTIFICATE"

source ./data.sh

function press_enter() {
  echo ""
  read -p "Press <Enter> to continue.." enter
}

# Recapitulation
echo "Certificate name: $TLS_CERTIFICATE"
press_enter

sudo mkdir -p $STORAGE/{auth,certs,data}

# Non CA Certificate is not usable!
# cd $STORAGE/certs && openssl req -newkey rsa:4096 -nodes -sha256 -keyout $TLS_CERTIFICATE.key -x509 -days 365 -out $TLS_CERTIFICATE.crt
# cp $STORAGE/certs/$TLS_CERTIFICATE.crt /etc/pki/ca-trust/source/anchors/

## Jen jednou spustit a když je to v nastavení clusteru tak už se nesmí změnit jinak to cluster nebude znát..
if [ ! -e "$STORAGE/certs/$TLS_CERTIFICATE-ca.key" ]; then
  echo "Generating certificates.."
	press_enter
	echo ""
  sudo openssl genrsa -out $STORAGE/certs/$TLS_CERTIFICATE-ca.key 2048
  sudo openssl req -x509 -new -key $STORAGE/certs/$TLS_CERTIFICATE-ca.key -out $STORAGE/certs/$TLS_CERTIFICATE-ca.crt -days 1460 -subj "/C=CZ/ST=CZ/L=test/O=Nutius Ltd/OU=Nutius Security Department/CN=apps.atemi.nutius.com"
  sudo openssl genrsa -out $STORAGE/certs/$TLS_CERTIFICATE.key 2048
  sudo openssl req -new -key $STORAGE/certs/$TLS_CERTIFICATE.key -out $STORAGE/certs/$TLS_CERTIFICATE.csr -subj "/C=CZ/ST=CZ/L=test/O=Nutius Ltd/OU=test/CN=$HOST"
  sudo openssl x509 -req -in $STORAGE/certs/$TLS_CERTIFICATE.csr -CA $STORAGE/certs/$TLS_CERTIFICATE-ca.crt -CAkey $STORAGE/certs/$TLS_CERTIFICATE-ca.key -CAcreateserial -out $STORAGE/certs/$TLS_CERTIFICATE.crt -days 365
fi

sudo cp $STORAGE/certs/$TLS_CERTIFICATE.crt /etc/pki/ca-trust/source/anchors/
sudo cp $STORAGE/certs/$TLS_CERTIFICATE-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
#
# Nevím tady jestli se musí i $TLS_CERTIFICATE-ca kopírovat do složky s důvěryhodnými certifikáty tady..
#
