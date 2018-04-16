#!/bin/bash

set -e

URL="https://localhost:9443/in/simple_json"

cp ./delayed_say_hello.json /tmp/$$.json

if [ ! -z "$1" ]; then
        sed -i "s/john.doe/${1}/g" /tmp/$$.json
fi

if [ ! -z "$2" ]; then
        echo "replace delay by $2"
        sed -i "s/PT10S/PT${2}S/g" /tmp/$$.json
fi

curl -k -H "Content-Type: application/json" -d @/tmp/$$.json -X POST $URL

cat /tmp/$$.json

rm -f /tmp/$$.json
