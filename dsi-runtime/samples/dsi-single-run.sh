#!/bin/bash

# Example of a typical start of DSI single runtime with Docker Compose

set -e

SRC_DIR=`dirname $0`

cd $SRC_DIR/..
echo Run docker-compose from `pwd`
docker-compose up -d

DSI_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dsiruntime_dsi-runtime_1`
echo "IP Adress of the DSI runtime: $DSI_IP"
