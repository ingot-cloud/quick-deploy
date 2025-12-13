#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

source ./.env

mkdir -p ${BROKER1_VOLUME}
chown -R 1000:1000 ${BROKER1_VOLUME}
chmod -R 755 ${BROKER1_VOLUME}

docker compose up -d