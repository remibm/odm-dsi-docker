#!/bin/bash

set -e

function solution_deploy {
        DSI_IP=$1
        docker-compose run --rm -v $SRC_DIR:/dropins dsi-runtime /dsi-cmd solutionManager deploy remote /dropins/simple_solution-0.0.esa \
        --host=$DSI_IP --port=$RUNTIME_PORT $SOL_MANAGER_OPTS || echo "Deploy failed, solution could be already deployed on $DSI_IP"
}

function connectivity_deploy {
        DSI_IP=$1
        docker-compose run --rm -v $SRC_DIR:/dropins dsi-runtime /dsi-cmd connectivityManager deploy remote /dropins/simple_solution-0.0.esa \
        /dropins/in-connectivity-server-configuration.xml --host=$DSI_IP --port=$INBOUND_PORT $SOL_MANAGER_OPTS \
        || echo "Deploy failed, connectivity could be already deployed on $DSI_IP"
}

function setvar {
        VALUE="${@:2}"
        eval export $1=\"$VALUE\"
        echo "$1=$VALUE"
}


# this script is meant to be executed from sample directory
cd `dirname $0`
SRC_DIR=`pwd`

setvar ESA "simple_solution-0.0.esa"
setvar INCONN "in-connectivity-server-configuration.xml"

setvar RUNTIME_IPS `docker-compose logs dsi-runtime | egrep "IP of the DSI server is" | awk '{print $NF}' | sed "s/\n/ /" | perl -ne 's/\n/ /g;print'`
setvar INBOUND_IPS `docker-compose logs dsi-runtime-inbound | egrep "IP of the DSI server is" | awk '{print $NF}' | sed "s/\n/ /" | perl -ne 's/\n/ /g;print'`

setvar RUNTIME_PORT 9443
setvar INBOUND_PORT 9444

SOL_MANAGER_OPTS="--sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"

for DSI_IP in `echo $RUNTIME_IPS` ; do
        echo "Deploy solution on $DSI_IP"
        solution_deploy $DSI_IP
done

for DSI_IP in `echo $INBOUND_IPS` ; do
        echo "Deploy connectivity on $DSI_IP"
        connectivity_deploy $DSI_IP
done
