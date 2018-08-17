#!/bin/bash

set -e

function print_usage {
        echo "USAGE: $0 <DSI_IP> <DSI_PORT>"
}

if [ -z $2 ]; then
        print_usage
        exit 1
else
        DSI_IP="$1"
        DSI_PORT="$2"
fi

source ./.env

SOL_MANAGER_OPTS="--sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"

cd `dirname $0`

SRC_DIR=`pwd -P`

echo "Deploying solution to $DSI_IP"

# Deploy the solution
docker-compose run -v $SRC_DIR/target:/dropins dsi-runtime /dsi-cmd solutionManager deploy remote /dropins/simple_solution-0.0.esa --host=$DSI_IP --port=$DSI_PORT $SOL_MANAGER_OPTS

# Deploy the connectivity configuration

# Replace OUTPUT_CONNECTIVITY_URL text by its associated variable: ${OUTPUT_CONNECTIVITY_URL} into connectivity-server-configuration.xml file.
ESCAPED_URL=`echo $OUTPUT_CONNECTIVITY_URL|sed -e 's@\/@\\\/@g'`

sed -i -e "s@OUTPUT_CONNECTIVITY_URL@${ESCAPED_URL}@g" ./target/connectivity-server-configuration.xml

docker-compose run -v $SRC_DIR/target:/dropins dsi-runtime /dsi-cmd connectivityManager deploy remote /dropins/simple_solution-0.0.esa /dropins/connectivity-server-configuration.xml --host=$DSI_IP --port=$DSI_PORT $SOL_MANAGER_OPTS
