# final-code - Ex - SSL - Transport Security in Practice

The end state of the exercise. Compare against it when your own version stops
working, or start from here if you fell behind.

## Make the certificates first

The key material is not in this repository on purpose - a keystore holding a
private key never belongs in Git. Regenerate everything with one command:

```bash
bash tls/make-certs.sh
```

## Run it

```bash
./mvnw quarkus:dev
curl --cacert tls/ca.crt https://localhost:8443/hello
```

## The Java client (step 4)

```bash
java client/SimpleClient.java                      # fails: PKIX path building failed
java -Djavax.net.ssl.trustStore=tls/truststore.p12 \
     -Djavax.net.ssl.trustStorePassword=changeit \
     client/SimpleClient.java                      # works
java client/TrustingClient.java                    # same, but wired up in code
```

## TLS offloading behind Traefik (step 5)

```bash
cd docker
docker compose up -d
curl --cacert ../tls/ca.crt https://localhost/
```

## The ACME HTTP-01 challenge against a local test CA (step 5b)

```bash
cd docker
docker compose -f compose.acme.yaml up -d
docker compose -f compose.acme.yaml logs -f pebble
curl -sk https://localhost:15000/roots/0 -o pebble-root.crt
curl --cacert pebble-root.crt --resolve app.htl.test:443:127.0.0.1 https://app.htl.test/
```

## Versions this was built and verified against

- Quarkus 3.39.4, JDK 21
- Traefik v3.7 - v3.4 fails against Docker Engine 29 (`client version 1.24 is too old`)
- OpenSSL 3.6, Docker 29.7
