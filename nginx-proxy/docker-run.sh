#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/nginx-proxy/conf
mkdir -p /ingot-data/docker/volumes/nginx-proxy/vhost
mkdir -p /ingot-data/docker/volumes/nginx-proxy/html
mkdir -p /ingot-data/docker/volumes/nginx-proxy/dhparam
mkdir -p /ingot-data/docker/volumes/nginx-proxy/certs
mkdir -p /ingot-data/docker/volumes/nginx-proxy/acme


docker compose -f ${currentPath}/docker-compose.yml up -d
