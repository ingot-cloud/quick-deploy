#!/usr/bin/env bash

source ./.env

mkdir -p ${WORK_DIR}/volumes/nginx-proxy/conf
mkdir -p ${WORK_DIR}/volumes/nginx-proxy/vhost
mkdir -p ${WORK_DIR}/volumes/nginx-proxy/html
mkdir -p ${WORK_DIR}/volumes/nginx-proxy/dhparam
mkdir -p ${WORK_DIR}/volumes/nginx-proxy/certs
mkdir -p ${WORK_DIR}/volumes/nginx-proxy/acme

docker compose -f ./docker-compose.yml up -d
