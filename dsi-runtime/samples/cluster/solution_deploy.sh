#!/bin/bash

set -e

function print_usage {
        echo "USAGE: $0 <DSI_HOME>"
}

function get_ip {
        echo `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1`
}

function get_host_port {
        echo `docker inspect -f '{{ (index (index .NetworkSettings.Ports "9443/tcp") 0).HostPort }}' $1`
}

if [ -z "$1" ]; then
        print_usage
        exit 1
fi

DSI_HOME="$1"

SRC_DIR=`dirname $0`

ESA="$SRC_DIR/simple_solution-0.0.esa"
INCONN="$SRC_DIR/in-connectivity-server-configuration.xml"

CONTAINER1=`get_ip dsi-runtime-container1`
CONTAINER2=`get_ip dsi-runtime-container2`
CONTAINER3=`get_ip dsi-runtime-container3`
INBOUND=`get_ip dsi-runtime-inbound`

echo "CONTAINER1=$CONTAINER1"
echo "CONTAINER2=$CONTAINER2"
echo "CONTAINER3=$CONTAINER3"
echo "INBOUND=$INBOUND"

if [[ "$OSTYPE" == "darwin"* ]]; then
	CONTAINER1_PORT=`get_host_port dsi-runtime-container1`
	CONTAINER2_PORT=`get_host_port dsi-runtime-container2`
	CONTAINER3_PORT=`get_host_port dsi-runtime-container3`
	INBOUND_PORT=`get_host_port dsi-runtime-inbound`

    echo "CONTAINER1_PORT=$CONTAINER1_PORT"
    echo "CONTAINER2_PORT=$CONTAINER2_PORT"
    echo "CONTAINER3_PORT=$CONTAINER3_PORT"
    echo "INBOUND_PORT=$INBOUND_PORT"
fi

SOL_DEPLOY="$SRC_DIR/../solution_deploy.sh"

if [[ "$OSTYPE" == "darwin"* ]]; then
        $SOL_DEPLOY $DSI_IMAGE localhost $CONTAINER1_PORT $ESA
	$SOL_DEPLOY $DSI_IMAGE localhost $CONTAINER2_PORT $ESA
        $SOL_DEPLOY $DSI_IMAGE localhost $CONTAINER3_PORT $ESA
else
	$SOL_DEPLOY $DSI_IMAGE $CONTAINER1 9443 $ESA
	$SOL_DEPLOY $DSI_IMAGE $CONTAINER2 9443 $ESA
	$SOL_DEPLOY $DSI_IMAGE $CONTAINER3 9443 $ESA
fi

echo "calling connectivity deploy to inbound"

CONN_DEPLOY="$SRC_DIR/../conn_deploy.sh"

if [[ "$OSTYPE" == "darwin"* ]]; then
	$CONN_DEPLOY $DSI_IMAGE localhost $INBOUND_PORT $ESA $INCONN
else
	$CONN_DEPLOY $DSI_IMAGE $INBOUND 9443 $ESA $INCONN
fi
