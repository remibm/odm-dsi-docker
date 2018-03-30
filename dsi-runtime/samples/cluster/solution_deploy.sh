#!/bin/bash

set -e

function print_usage {
        echo "USAGE: $0" 
}

function get_ip {
        echo `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1`
}

function get_host_port {
        echo `docker inspect -f '{{ (index (index .NetworkSettings.Ports "9443/tcp") 0).HostPort }}' $1`
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
        --host=$DSI_IP --port=$RUNTIME_PORT $SOL_MANAGER_OPTS || echo "Deploy failed, solution could be already deployed on $DSI_IP"
}

function connectivity_deploy {
        setvar DSI_IP "$1"
        setvar INBOUND_PORT "$2"
        echo deploying connectivity on "$DSI_IP:$INBOUND_PORT"
        docker-compose run --rm -v $SRC_DIR:/dropins dsi-runtime-container1 /dsi-cmd connectivityManager deploy remote /dropins/simple_solution-0.0.esa \
        /dropins/in-connectivity-server-configuration.xml --server=dsi-runtime-inbound --host=$DSI_IP --port=$INBOUND_PORT $SOL_MANAGER_OPTS  \
        || echo "Deploy failed, connectivity could be already deployed on $DSI_IP"

}

if [[ "$#" -ne 0 ]]; then
        print_usage
        exit 1
fi

cd `dirname $0`
SRC_DIR=`pwd`
 
setvar ESA "$SRC_DIR/simple_solution-0.0.esa"
setvar INCONN "$SRC_DIR/in-connectivity-server-configuration.xml"

setvar CONTAINER1 `get_ip dsi-runtime-container1`
setvar CONTAINER2 `get_ip dsi-runtime-container2`
setvar CONTAINER3 `get_ip dsi-runtime-container3`
setvar INBOUND `get_ip dsi-runtime-inbound`
setvar SOL_MANAGER_OPTS "--sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"


if [[ "$OSTYPE" == "darwin"* ]]; then
	setvar CONTAINER1_PORT `get_host_port dsi-runtime-container1`
	setvar CONTAINER2_PORT `get_host_port dsi-runtime-container2`
	setvar CONTAINER3_PORT `get_host_port dsi-runtime-container3`
	setvar INBOUND_PORT `get_host_port dsi-runtime-inbound`
fi

#if [[ "$OSTYPE" == "darwin"* ]]; then
#        solution_deploy localhost $CONTAINER1_PORT 
#	solution_deploy localhost $CONTAINER2_PORT 
#        solution_deploy localhost $CONTAINER3_PORT 
#else
	solution_deploy $CONTAINER1 9443
	solution_deploy $CONTAINER2 9443
	solution_deploy $CONTAINER3 9443
#fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	connectivity_deploy localhost $INBOUND_PORT
else
	connectivity_deploy $INBOUND 9443 
fi
