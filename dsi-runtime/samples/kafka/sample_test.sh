#!/bin/bash

set -e

if [ ! -z "$1" ]; then
        TMP_DIR="/tmp/sample-kafka-$$"

        mkdir -p "$TMP_DIR"
        cd "$TMP_DIR"

        git clone https://github.com/ODMDev/odm-dsi-docker

        cd "$TMP_DIR/odm-dsi-docker/dsi-runtime/samples/kafka/"
fi

./start.sh

docker-compose down -v

if [ ! -z "$1" ]; then
        rm -r "$TMP_DIR"
fi
