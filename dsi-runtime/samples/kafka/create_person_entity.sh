#!/bin/bash

set -e

echo "Creating Person entity ..."

docker-compose exec dsi-runtime /dropins/create_person.sh
