#!/bin/bash

set -e

TMP_DIR="/tmp/sample-kafka-$$"

mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

git clone https://github.com/ODMDev/odm-dsi-docker

cd dsi-runtime/samples/kafka/
./start.sh

rm -r "$TMP_DIR"
