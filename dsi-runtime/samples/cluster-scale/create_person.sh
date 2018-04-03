#!/bin/bash

# This script is sending an event to DSI Runtime which creates
# an entity Person.
#
# First argument is the hostname of the DSI Runtime.
# Second argument is the name of the person.

set -e

function print_usage {
        echo "USAGE: $0 <PERSON_NAME>"
}



if [ -z "$1" ]; then
        PERSON="john.doe"
else
        PERSON="$1"
fi

cp ./create_person.xml /tmp/$$.tmp

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i'' -e "s/ID/$PERSON/" /tmp/$$.tmp
else
    sed -i "s/ID/$PERSON/" /tmp/$$.tmp
fi

#DSI_HOSTNAME=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dsi-runtime-inbound`

URL=https://localhost:9444/in/simple

echo "Endpoint URL: $URL"

cat /tmp/$$.tmp

curl --user tester:tester -k -H "Content-Type: application/xml" -d @/tmp/$$.tmp -X POST $URL

rm /tmp/$$.tmp
