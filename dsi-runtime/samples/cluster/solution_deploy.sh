#!/bin/bash

set -e

function print_usage {
        echo "USAGE: $0" 
}

function get_ip {
        echo `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1`
}

function setvar {
        VALUE="${@:2}"
        eval export $1=\"$VALUE\"
        echo "$1=$VALUE"
}

function solution_deploy {
        setvar DSI_IP "$1"
        setvar RUNTIME_PORT "$2"
        echo deploying solution on "$DSI_IP:$RUNTIME_PORT"
        docker-compose run --rm -v $SRC_DIR:/dropins dsi-runtime-container1 /dsi-cmd solutionManager deploy remote /dropins/simple_solution-0.0.esa \
        --host=$DSI_IP --port=$RUNTIME_PORT $SOL_MANAGER_OPTS || echo "Solution deployment failed on $DSI_IP"
}

function connectivity_deploy {
        setvar DSI_IP "$1"
        setvar INBOUND_PORT "$2"
        echo deploying connectivity on "$DSI_IP:$INBOUND_PORT"
        docker-compose run --rm -v $SRC_DIR:/dropins dsi-runtime-container1 /dsi-cmd connectivityManager deploy remote /dropins/simple_solution-0.0.esa \
        /dropins/in-connectivity-server-configuration.xml --server=dsi-runtime-inbound --host=$DSI_IP --port=$INBOUND_PORT $SOL_MANAGER_OPTS  \
        || echo "Connectivity deployment failed on $DSI_IP"

}

if [[ "$#" -ne 0 ]]; then
        print_usage
        exit 1
fi

SRC_DIR=`dirname $0`
cd SRC_DIR
 
setvar ESA "$SRC_DIR/simple_solution-0.0.esa"
setvar INCONN "$SRC_DIR/in-connectivity-server-configuration.xml"

setvar CONTAINER1 `get_ip dsi-runtime-container1`
setvar CONTAINER2 `get_ip dsi-runtime-container2`
setvar CONTAINER3 `get_ip dsi-runtime-container3`
setvar INBOUND `get_ip dsi-runtime-inbound`
setvar SOL_MANAGER_OPTS "--sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"


solution_deploy $CONTAINER1 9443
solution_deploy $CONTAINER2 9443
solution_deploy $CONTAINER3 9443

connectivity_deploy $INBOUND 9443 
