# !/bin/bash -e

# Create Root CA (Done once)
# https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309

# Create Root Key:
openssl genrsa -des3 -out rootCA.key 4096

## Create and self sign the Root Certificate:
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt

# Create a certificate (Done for each server):

## Create the certificate key:
openssl genrsa -out example.com.key 2048
# openssl req -new -sha256 -key example.com.key -subj "/C=CZ/ST=ZL/O=Focarso, Inc./CN=example.com" -out example.com.csr

##Create the signing (csr)
openssl req -new -key example.com.key -subj "/C=CZ/ST=ZL/O=Focarso, Inc./CN=example.com" -out example.com.csr

##Verify the csr's content:
openssl req -in example.com.csr -noout -text

##Generate the certificate using the mydomain csr and key along with the CA Root key:
openssl x509 -req -in example.com.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out example.com.crt -days 500 -sha256

##Verify the certificate's content:
openssl x509 -in example.com.crt -text -noout
