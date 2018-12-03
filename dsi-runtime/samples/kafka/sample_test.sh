#!/bin/bash

set -e

function isready() {
        docker-compose exec dsi-runtime /dsi-cmd solutionManager isready simple_solution --disableSSLHostnameVerification=true --disableServerCertificateVerification=true | grep "is ready"
}

function isentitycreated() {
        docker-compose exec dsi-runtime wget -qO- --no-check-certificate https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person/entities | grep "john.doe"
}

if [ ! -z "$1" ]; then
        TMP_DIR="/tmp/sample-kafka-$$"

        mkdir -p "$TMP_DIR"
        cd "$TMP_DIR"

        git clone https://github.com/ODMDev/odm-dsi-docker

        cd "$TMP_DIR/odm-dsi-docker/dsi-runtime/samples/kafka/"
fi

# Stats the DSI runtime, Kafka and Zookeeper
./start.sh

# Wait until the solution is ready
until [ "$ISREADY" == "1" ]
do
        echo "Checking whether DSI solution is ready after 2s"
        sleep 2
        ISREADY=`isready >/dev/null && echo 1 || echo 0`
done

# Sends an event to a Kafka topic which will create an entity
./create_person_entity.sh

# Waits until the entity is created
until [ "$ISCREATED" == "1" ]
do
        echo "Checking whether the entity is created after 2s"
        sleep 2
        ISCREATED=`isentitycreated >/dev/null && echo 1 || echo 0`
done

docker-compose down -v

if [ ! -z "$1" ]; then
        rm -r "$TMP_DIR"
fi
