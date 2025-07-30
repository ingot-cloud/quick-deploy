#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

source ./.env

mkdir -p /ingot-data/docker/volumes/kafka/${BROKER1_NAME}

docker compose up -d