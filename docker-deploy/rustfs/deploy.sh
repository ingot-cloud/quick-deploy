#!/usr/bin/env bash

source ./.env

mkdir -p ${DOCKER_VOLUME}/data
mkdir -p ${DOCKER_VOLUME}/logs
 # Change the owner of these directories
chown -R 10001:10001 ${DOCKER_VOLUME}/data ${DOCKER_VOLUME}/logs

docker compose up -d