#!/bin/bash

set -e

curl -s --user tester:tester -k -H "Accept: application/$2" https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person/entities/$1
