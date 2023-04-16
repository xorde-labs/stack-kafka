#!/bin/sh

### Script to send test message to Apache Kafka

ENV_FILE=../.env
OS="`uname`"

case $OS in
  'Linux')
    KAFKACAT=kafkacat
    UUID=$(cat /proc/sys/kernel/random/uuid)
  ;;
  'FreeBSD')
    KAFKACAT=kafkacat
    UUID=$(cat /proc/sys/kernel/random/uuid)
  ;;
  'Darwin')
    KAFKACAT=kcat # install with "brew install kcat"
    UUID=$(/usr/bin/uuidgen)
  ;;
  *) ;;
esac

UUID=$(echo "$UUID" | tr '[:upper:]' '[:lower:]')

### Load environment variables
# shellcheck disable=SC2046
if [ -f "$ENV_FILE" ]; then export $(cat "$ENV_FILE" | sed 's/#.*//g' | xargs); fi

### Construct payload message
PAYLOAD="$(cat <<-EOF
{
  "side": 1,
  "type": 0,
  "tags": ["send-kafka-test-message.sh"],
  "parent": "7133cd16-cead-41a3-bd48-04df29f83f9f",
  "amount": 0.00040,
  "pair": "btc-usdt",
  "exchange": "binance",
  "userId": "$BINANCE_DEFAULT_ID",
  "id": "$UUID",
  "state": 0,
  "manual": true
}
EOF
)"

TOPIC=${KAFKA_TOPIC:-test_topic}
JSON=$(echo "$PAYLOAD" | tr -d '\n ')
echo "TOPIC: $TOPIC JSON: $JSON"

# shellcheck disable=SC2086
echo $JSON | ${KAFKACAT} -P -Z -b "$KAFKA_BROKERS" \
  -k $UUID \
  -t $TOPIC \
  -X enable.ssl.certificate.verification=false \
  -X security.protocol=SASL_SSL \
  -X sasl.mechanisms=PLAIN \
  -X sasl.username=$KAFKA_USERNAME \
  -X sasl.password=$KAFKA_PASSWORD
