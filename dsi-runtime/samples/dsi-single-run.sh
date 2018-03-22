#!/bin/bash

# Example of a typical start of DSI single runtime with Docker Compose

set -e

SRC_DIR=`dirname $0`

cd $SRC_DIR
docker-compose up -d
