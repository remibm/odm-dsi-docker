#!/bin/bash

# This script deploys the connectivity configuration.
#
# USAGE: $0 <DSI_HOME> <DSI_HOSTNAME> <DSI_PORT> <ESA> <CONFIG_XML>

# DSI_HOME is the installation directory of ODM Insights
# DSI_HOSTNAME is the hostname of the DSI Runtime.
# DSI_PORT is the port of the DSI Runtime.
# ESA the path to the .esa file of the solution
# CONFIG_XML the path to the configuration file of the solution connectivity.

set -e

function print_usage {
        echo "USAGE: $0 <DSI_IMAGE> <DSI_HOSTNAME> <DSI_PORT> <ESA> <CONFIG_XML>"
}

if [ -z "$5" ]; then
        print_usage
        exit 1
else
        DSI_IMAGE="$1"
        DSI_HOSTNAME="$2"
        DSI_PORT="$3"
        ESA="$4"
        CONN="$5"
fi

SRC_DIR=`dirname $0`

OPTIONS="--sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester

export DROPINSDIR=/tmp/dropins.$$
mkdir $DROPINSDIR
cp  $ESA $DROPINSDIR/mysol.esa
cp $CONN $DROPINSDIR/connectivity.xml

docker-compose run -v $DROPINSDIR:/dropins $DSI_IMAGE /dsi-cmd solutionManager deploy remote /dropins/mysol.esa \
--host=$DSI_HOSTNAME --port=9443 $OPTIONS

docker-compose run -v $DROPINSDIR:/dropins $DSI_IMAGE /dsi-cmd connectivityManager deploy remote $ESA $CONN $OPTIONS --host=$DSI_HOSTNAME --port=$DSI_PORT

