#!/bin/bash

# This script is building the Docker image of DSI runtime.
# It requires a Linux installation of ODM Insights v8.9.
# The instructions are available at: https://github.com/ODMDev/odm-dsi-docker.
#
# If set the DSI templates will be copied from the environment variable
# DSI_TEMPLATES.

set -e

function print_usage {
        echo "USAGE: $0 <DSI_HOME> <DSI_IMAGE>"
}

if [ -z "$1" ]; then
        print_usage
        exit 1
else
        DSI_HOME="$1"
fi

DSI_HOME_RUNTIME="$DSI_HOME/runtime"
if [ ! -d "$DSI_HOME_RUNTIME" ]; then
        >&2 echo "The directory $DSI_HOME_RUNTIME does not exist."
        exit 1
fi

export BUILD_DIR="/tmp/dsi-docker-build.$$"
BUILD_DIR_DSI="$BUILD_DIR/opt/dsi"
BUILD_DIR_DSI_RUNTIME="$BUILD_DIR_DSI/runtime"
SRC_DIR=`dirname $0`

echo "Creating the build file"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR_DSI_RUNTIME"

echo "Copying DSI from $DSI_HOME_RUNTIME to $BUILD_DIR_DSI_RUNTIME."
cp -rp "$DSI_HOME_RUNTIME/"* "$BUILD_DIR_DSI_RUNTIME"

if [ -z "$2" ]; then
        if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "cygwin" ]]; then
                echo "Copying JDK to $BUILD_DIR_DSI."
                cp -rp "$DSI_HOME/jdk" "$BUILD_DIR_DSI"
        fi
fi

echo "Cleanup DSI installation"
rm -rf "$BUILD_DIR_DSI_RUNTIME/wlp/usr/servers/"
rm -rf "$BUILD_DIR_DSI_RUNTIME/wlp/usr/extension/lib"

if [ -z "$DSI_TEMPLATES" ]; then
        DSI_TEMPLATES="$SRC_DIR/templates"
fi
echo "Copying DSI configuration templates from $DSI_TEMPLATES to $BUILD_DIR_DSI_RUNTIME/wlp/templates"
cp -rp $DSI_TEMPLATES/servers "$BUILD_DIR_DSI_RUNTIME/wlp/templates/"

echo "Copying docker container start script to $BUILD_DIR"
cp "$SRC_DIR/start.sh" "$SRC_DIR/dsi-cmd" "$BUILD_DIR"
cp "$SRC_DIR/jprofiler_config.xml" "$BUILD_DIR"

cp "$SRC_DIR/Dockerfile" "$BUILD_DIR"

if [ -z "$2" ]; then
        if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "cygwin" ]]; then
                docker-compose -f docker-compose-build.yaml build
        else
                docker-compose -f docker-compose-build.yaml build dsi-runtime-ibmjava
                docker-compose -f docker-compose-build.yaml build dsi-runtime-openjdk
        fi
else
        docker-compose build "$2"
fi
