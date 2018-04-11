#!/bin/bash

set -e

URL="https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person/entities/$1"

TMP_FILE="/tmp/$0-$$.tmp"
PERSON="$1"
DESCRIPTION="$2"

cp ./person_set.xml $TMP_FILE

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i'' -e "s/ID/$PERSON/" $TMP_FILE
    sed -i'' -e "s/DESCRIPTION/$DESCRIPTION/" $TMP_FILE
else
    sed -i "s/ID/$PERSON/" $TMP_FILE
    sed -i "s/DESCRIPTION/$DESCRIPTION/" $TMP_FILE
fi

curl -k -H "Content-Type: application/xml" -d @$TMP_FILE -X PUT $URL

rm $TMP_FILE
