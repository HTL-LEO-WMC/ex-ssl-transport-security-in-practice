#!/usr/bin/env bash
# Rebuilds every key, certificate and store this exercise uses.
# Run it from the project root:   bash tls/make-certs.sh
#
# Nothing in here is secret - these certificates are worth nothing outside your
# own laptop. That is also why the generated files are git-ignored: a keystore
# with a private key in it never belongs in a repository.
set -euo pipefail
cd "$(dirname "$0")"

echo "== step 1: a self-signed certificate, made by keytool =="
rm -f selfsigned-keystore.p12
keytool -genkeypair \
  -alias secure-service \
  -keyalg RSA -keysize 2048 \
  -dname "CN=localhost, OU=SafeLearn, O=HTL Leonding, C=AT" \
  -ext "SAN=dns:localhost,ip:127.0.0.1" \
  -validity 365 \
  -storetype PKCS12 \
  -keystore selfsigned-keystore.p12 \
  -storepass changeit

echo "== step 3a: our own root CA =="
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout ca.key -out ca.crt \
  -subj "/C=AT/O=HTL Leonding/CN=SafeLearn Root CA" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
  -addext "keyUsage=critical,keyCertSign,cRLSign"

echo "== step 3b: the server key and its signing request =="
openssl req -newkey rsa:2048 -nodes \
  -keyout server.key -out server.csr \
  -subj "/C=AT/O=HTL Leonding/CN=localhost"

echo "== step 3c: the CA signs the request =="
openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 365 -sha256 \
  -extfile server-ext.cnf \
  -out server.crt

echo "== step 3d: key + certificate + chain into one keystore =="
openssl pkcs12 -export \
  -inkey server.key -in server.crt -certfile ca.crt \
  -name secure-service \
  -out server-keystore.p12 -passout pass:changeit

echo "== step 4: a trust store holding nothing but our CA =="
rm -f truststore.p12
keytool -importcert -noprompt \
  -alias safelearn-ca -file ca.crt \
  -keystore truststore.p12 -storetype PKCS12 -storepass changeit

echo
echo "done - the certificate chain checks out:"
openssl verify -CAfile ca.crt server.crt
