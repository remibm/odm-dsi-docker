#!/bin/bash

set -e

echo "Starting Kafka events consumer ..."

docker-compose exec dsi-runtime /dropins/kafka_consume.sh
