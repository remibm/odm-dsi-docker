#!/bin/bash

set -e

URL="https://localhost:9443/in/simple_json"

cp ./say_hello.json /tmp/$$.json

if [ ! -z "$1" ]; then
        sed -i "s/john.doe/${1}/g" /tmp/$$.json
fi

curl -s --user tester:tester -k -H "Content-Type: application/json" -d @/tmp/$$.json -X POST $URL

rm -f /tmp/$$.json
