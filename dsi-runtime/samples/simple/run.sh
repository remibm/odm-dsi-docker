#!/bin/bash

set -e

cd `dirname $0`
SRC_DIR=`pwd -P`

function isonline() {
        SOL_MANAGER_OPTS="--host=$1 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"
        docker-compose run dsi-runtime /dsi-cmd serverManager isonline $SOL_MANAGER_OPTS
}

function isSolutionReady() {
        SOL_MANAGER_OPTS="--host=$1 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"
        docker-compose run dsi-runtime /dsi-cmd solutionManager isready simple_solution $SOL_MANAGER_OPTS
}

echo "Starts single DSI Runtime"
../dsi-single-run.sh

cd $SRC_DIR/../..
CONTAINER_ID=`docker-compose ps -q`
echo "DSI container: $CONTAINER_ID"

DSI_IP=`docker exec $CONTAINER_ID hostname -I`
echo "DSI IP: $DSI_IP"

# wait until DSI is ready
until [ "$ISONLINE" == "1" ]
do
        echo "Waiting 5s before checking that DSI runtime is online"
        sleep 5
        ISONLINE=`isonline $DSI_IP >/dev/null && echo 1 || echo 0`
        echo "Is online result: $ISONLINE"
done

echo "Deploys solution"
$SRC_DIR/solution_deploy.sh $DSI_IP 9443

# waiting the solution to be ready
until [ "$ISSOLREADY" == "1" ]
do
        echo "Waiting 5s before checking that the solution is ready"
        sleep 5
        ISSOLREADY=`isSolutionReady $DSI_IP >/dev/null && echo 1 || echo 0`
        echo "Is solution ready result: $ISSOLREADY"
done

# waiting the connectivity to be ready
sleep 30

echo "Create a person"
cd $SRC_DIR
./create_person.sh localhost john.doe
