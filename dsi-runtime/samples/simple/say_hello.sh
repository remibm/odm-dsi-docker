#!/bin/bash

set -e

URL="https://localhost:9443/in/simple_json"

curl -k -H "Content-Type: application/json" -d @./say_hello.json -X POST $URL
