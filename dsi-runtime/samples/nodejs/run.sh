#!/bin/bash

set -e

function isonline() {
        SOL_MANAGER_OPTS="--host=$1 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"
        docker-compose run dsi-runtime /dsi-cmd serverManager isonline $SOL_MANAGER_OPTS
}

docker build -t nodejs-bridge .

echo "Create DSI Docker containers"

docker-compose up -d

DSI_HOSTNAME=`docker-compose exec dsi-runtime hostname -i | sed 's/\r//g'`

echo "DSI hostname: $DSI_HOSTNAME"

# wait until DSI is ready
until [ "$ISONLINE" == "1" ]
do
        echo "Checking whether DSI is online after 5s"
        sleep 5
        ISONLINE=`isonline $DSI_HOSTNAME >/dev/null && echo 1 || echo 0`
done

echo "DSI runtime is ready"

./solution_deploy.sh "$DSI_HOSTNAME" 9443
