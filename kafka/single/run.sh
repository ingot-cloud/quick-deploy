#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

source ./.env

mkdir -p ${BROKER1_VOLUME}

docker compose up -d