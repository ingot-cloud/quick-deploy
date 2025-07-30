#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

source ./.env

mkdir -p ${BROKER1_VOLUME}
mkdir -p ${BROKER2_VOLUME}
mkdir -p ${BROKER3_VOLUME}

docker compose up -d