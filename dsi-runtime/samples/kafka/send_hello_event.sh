#!/bin/bash

set -e

echo "Sending hello event ..."

docker-compose exec dsi-runtime /dropins/say_hello.sh
