#!/bin/sh
### This scripts is fully POSIX compliant.

pwd=$(dirname "$0")
echo "----- pwd: $pwd"

### Setting variables:
output_dir="$pwd/build"
config_dir="$pwd/build/config"
src_dir="$pwd/src"
keystore_password="confluent"
cert_password="confluent"
cert_hostnames="localhost kafka0 kafka1 kafka2 kafka3"

### This script is used to generate the certificates for the Kafka cluster.
### Based on: https://developer.confluent.io/learn-kafka/security/hands-on-setting-up-encryption/

### You will need to update your docker-compose.yml file to include the following:

### docker-compose.yml:
:<<docker-compose-chunk
    environment:
      KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM: "HTTPS"
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INSECURE:PLAINTEXT,SECURE:SASL_SSL,BROKER:PLAINTEXT
# Newer versions for Kafka:
      KAFKA_SSL_KEYSTORE_LOCATION: /etc/kafka/secrets/cert.keystore
      KAFKA_SSL_KEYSTORE_PASSWORD: confluent
      KAFKA_SSL_KEY_PASSWORD: confluent
# Older versions of Kafka:
#      KAFKA_SSL_KEYSTORE_FILENAME: cert.keystore
#      KAFKA_SSL_KEYSTORE_CREDENTIALS: cert.keystore.creds
#      KAFKA_SSL_KEY_CREDENTIALS: cert.cert.creds
docker-compose-chunk

### Check if the certs directory already exists
if [ -d "$output_dir" ]; then
  echo "Output directory $output_dir already exists, exiting..."
  exit 1
fi

### Check if the src directory exists
if [ ! -d "$src_dir" ]; then
  echo "Source directory $src_dir does not exist, exiting..."
  exit 2
fi

"${pwd}"/src/build_configs.sh "$cert_hostnames" "$config_dir" || exit 3

echo "----- Creating output directory -----"
mkdir -p "$output_dir"

echo "----- Creating the certification authority key and certificate -----"
openssl req -new -nodes \
  -x509 \
  -days 365 \
  -newkey rsa:2048 \
  -keyout "$output_dir"/ca.key \
  -out "$output_dir"/ca.crt \
  -config "$config_dir"/ca.cnf

echo "----- Converting those files over to a .pem file -----"
cat "$output_dir"/ca.crt "$output_dir"/ca.key > "$output_dir"/ca.pem

echo "----- Creating the server key and certificate -----"
openssl req -new \
  -newkey rsa:2048 \
  -keyout "$output_dir"/cert.key \
  -out "$output_dir"/cert.csr \
  -config "$config_dir"/cert.cnf \
  -nodes

echo "----- Signing the certificate with the certificate authority -----"
openssl x509 -req \
  -days 3650 \
  -in "$output_dir"/cert.csr \
  -CA "$output_dir"/ca.crt \
  -CAkey "$output_dir"/ca.key \
  -CAcreateserial \
  -out "$output_dir"/cert.crt \
  -extfile "$config_dir"/cert.cnf \
  -extensions v3_req

echo "----- Converting the server certificate over to the pkcs12 format -----"
openssl pkcs12 -export \
  -in "$output_dir"/cert.crt \
  -inkey "$output_dir"/cert.key \
  -chain \
  -CAfile "$output_dir"/ca.pem \
  -name broker \
  -out "$output_dir"/cert.p12 \
  -password pass:"$cert_password"

echo "----- Creating the broker keystore and import the certificate -----"
# shellcheck disable=SC1001
keytool -importkeystore \
  -deststorepass "$keystore_password" \
  -destkeystore "$output_dir"/cert.keystore \
  -srckeystore "$output_dir"/cert.p12 \
  -deststoretype PKCS12  \
  -srcstoretype PKCS12 \
  -noprompt \
  -srcstorepass "$keystore_password"

echo "----- Verifying the broker keystore -----"
# shellcheck disable=SC1001
keytool -list -v \
    -keystore "$output_dir"/cert.keystore \
    -storepass "$keystore_password"

echo "----- Saving the credentials -----"
# shellcheck disable=SC1001
tee "$output_dir"/keystore.password << EOF >/dev/null
$keystore_password
EOF

# shellcheck disable=SC1001
tee "$output_dir"/cert.password << EOF >/dev/null
$cert_password
EOF

# shellcheck disable=SC1001
tee "$output_dir"/passwords.env << EOF >/dev/null
KAFKA_SSL_KEY_PASSWORD=$cert_password
KAFKA_SSL_KEYSTORE_PASSWORD=$keystore_password
EOF

cat << EOF
You can check connection with the following command:
  openssl s_client -connect <kafka_broker_host>:<kafka_broker_port> -tls1_3 -showcerts
Example:
  openssl s_client -connect localhost:9092 -tls1_3 -showcerts
EOF
