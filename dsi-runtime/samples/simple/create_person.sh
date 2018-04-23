#!/bin/bash

# This script is sending an event to DSI Runtime which creates
# an entity Person.
#
# First argument is the hostname of the DSI Runtime.
# Second argument is the name of the person.

set -e

function print_usage {
        echo "USAGE: $0 <DSI_HOSTNAME> <PERSON_NAME>"
}

if [ -z "$1" ]; then
        print_usage
        exit 1
else
        DSI_HOSTNAME="$1"
fi

if [ -z "$2" ]; then
        PERSON="jean"
else
        PERSON="$2"
fi

# This script is meant to be executed from script directory
SRC_DIR=`dirname $0`
cd $SRC_DIR


cp ./create_person.xml /tmp/$$.tmp

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i'' -e "s/ID/$PERSON/" /tmp/$$.tmp
else
    sed -i "s/ID/$PERSON/" /tmp/$$.tmp
fi

URL=https://$DSI_HOSTNAME:9443/in/simple

echo "Endpoint URL: $URL"

cat /tmp/$$.tmp

curl -k -H "Content-Type: application/xml" -d @/tmp/$$.tmp -X POST $URL

rm /tmp/$$.tmp
