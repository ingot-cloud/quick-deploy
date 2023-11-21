#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`

minio_version=latest
default_user=admin
default_user_pwd=12345678

mkdir -p /ingot-data/docker/volumes/minio/data
mkdir -p /ingot-data/docker/volumes/minio/config

docker run --name minio \
     --network ingot-net --ip 172.88.0.150 \
     -p 6001:5001 \
     -p 9090:9000 \
     -d --restart=always \
     -e MINIO_ROOT_USER=${default_user} \
     -e MINIO_ROOT_PASSWORD=${default_user_pwd} \
     -v /ingot-data/docker/volumes/minio/data:/data \
     minio/minio:${minio_version} 'server' '/data' '--console-address' ':5001' '-address' ':9000'