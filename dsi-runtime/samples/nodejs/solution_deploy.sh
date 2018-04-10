#!/bin/bash

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

SRC_DIR=`dirname $0`
SRC_DIR=`realpath $SRC_DIR`

SOL_MANAGER_OPTS="--sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"

SOL_DIR=`realpath $SRC_DIR`
echo "Directory containing the solution: $SOL_DIR"

echo "Deploy solution to DSI: $DSI_IP:$DSI_PORT"
docker-compose run -v $SOL_DIR:/dropins dsi-runtime /dsi-cmd solutionManager deploy remote /dropins/simple_solution-0.0.esa --host=$DSI_IP --port=$DSI_PORT $SOL_MANAGER_OPTS

echo "Deploy connectivity to DSI: $DSI_IP:$DSI_PORT from directory $CONN_DIR"
docker-compose run -v $SOL_DIR:/dropins dsi-runtime /dsi-cmd connectivityManager deploy remote /dropins/simple_solution-0.0.esa /dropins/connectivity-server-configuration.xml --host=$DSI_IP --port=$DSI_PORT $SOL_MANAGER_OPTS
