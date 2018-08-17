#!/bin/bash

set -e

cd /dropins/

source ./.env

echo "Kafka hostname: $KAFKA_HOSTNAME, kafka port: $KAFKA_PORT, kafka topic: $KAFKA_TOPIC_IN"

if [ -z "$JAVA_HOME" ]; then
        DSI_HOME="/opt/dsi"
        export JAVA_HOME="$DSI_HOME/jdk/jre"
fi

# Start the publisher Kafka client
$JAVA_HOME/bin/java -jar ./clients-1.0.jar publish $KAFKA_HOSTNAME $KAFKA_PORT $KAFKA_TOPIC_IN "$*"
