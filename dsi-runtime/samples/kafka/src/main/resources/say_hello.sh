#!/bin/bash

set -e

cd /dropins/

CONTENT=`cat ./say_hello.json | sed 's/\"/\\"/g'`

echo Post to Kafka server: "$CONTENT"

./kafka_publish.sh "$CONTENT"
