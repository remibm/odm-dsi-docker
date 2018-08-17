#!/bin/bash

set -e

function isready() {
        docker-compose exec dsi-runtime /dsi-cmd solutionManager isready simple_solution --disableSSLHostnameVerification=true --disableServerCertificateVerification=true | grep "is ready"
}

if [ ! -z "$1" ]; then
        TMP_DIR="/tmp/sample-kafka-$$"

        mkdir -p "$TMP_DIR"
        cd "$TMP_DIR"

        git clone https://github.com/ODMDev/odm-dsi-docker

        cd "$TMP_DIR/odm-dsi-docker/dsi-runtime/samples/kafka/"
fi

./start.sh

until [ "$ISREADY" == "1" ]
do
        echo "Checking whether DSI solution is ready after 2s"
        sleep 2
        ISREADY=`isready >/dev/null && echo 1 || echo 0`
done

docker-compose down -v

if [ ! -z "$1" ]; then
        rm -r "$TMP_DIR"
fi
