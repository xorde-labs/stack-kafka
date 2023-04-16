#!/bin/sh

docker-compose -f docker-compose.yml --env-file docker-compose.env up --force-recreate --remove-orphans -d
