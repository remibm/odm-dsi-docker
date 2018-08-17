#!/bin/bash

set -e

function isonline() {
        SOL_MANAGER_OPTS="--host=$1 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"
        docker-compose exec dsi-runtime /dsi-cmd serverManager isonline $SOL_MANAGER_OPTS
}

function get_ip {
        echo `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1`
}

# Setup environment variables
source ./.env

# Build all the projects
mvn clean install

# Deploy all the containers
docker-compose up -d

DSI_RUNTIME_HASH=`docker-compose ps -q dsi-runtime`
DSI_HOSTNAME=`get_ip $DSI_RUNTIME_HASH`
echo "DSI hostname: $DSI_HOSTNAME"

# wait until DSI is ready
until [ "$ISONLINE" == "1" ]
do
        echo "Checking whether DSI is online after 2s"
        sleep 2
        ISONLINE=`isonline $DSI_HOSTNAME >/dev/null && echo 1 || echo 0`
done

echo "DSI runtime is ready"

# Deploy the DSI solution
./solution_deploy.sh "$DSI_HOSTNAME" "$DSI_HTTPS_PORT"
