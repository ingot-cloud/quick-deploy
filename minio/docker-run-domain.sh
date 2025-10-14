#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`

VIRTUAL_HOST=minio.ingotcloud.top
VIRTUAL_PORT=5001

minio_version=RELEASE.2025-04-22T22-12-26Z
default_user=admin
default_user_pwd=12345678

mkdir -p /ingot-data/docker/volumes/minio/data
mkdir -p /ingot-data/docker/volumes/minio/config

docker run --name minio \
     --network ingot-net --ip 172.88.0.150 \
     -d --restart=always \
     -e VIRTUAL_HOST=${VIRTUAL_HOST} \
     -e VIRTUAL_PORT=${VIRTUAL_PORT} \
     -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
     -e MINIO_ROOT_USER=${default_user} \
     -e MINIO_ROOT_PASSWORD=${default_user_pwd} \
     -v /ingot-data/docker/volumes/minio/data:/data \
     docker-registry.ingotcloud.top/minio/minio:${minio_version} 'server' '/data' '--console-address' ':5001' '-address' ':9000'
