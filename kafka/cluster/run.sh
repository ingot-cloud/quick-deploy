#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

source ./.env

mkdir -p ${CLUSTER_BROKER1_VOLUME}
mkdir -p ${CLUSTER_BROKER2_VOLUME}
mkdir -p ${CLUSTER_BROKER3_VOLUME}

docker compose up -d