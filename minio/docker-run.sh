#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/minio/data
mkdir -p /ingot-data/docker/volumes/minio/config

VIRTUAL_HOST=minio.wangchao.im
VIRTUAL_PORT=5001

docker run --name minio \
     --network ingot-net --ip 172.88.0.100 \
     -p 5000:9000 \
     -d --restart=always \
     -e MINIO_ACCESS_KEY=admin \
     -e MINIO_SECRET_KEY=12345678 \
     -e VIRTUAL_HOST=${VIRTUAL_HOST} \
      -e VIRTUAL_PORT=${VIRTUAL_PORT} \
      -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
     -v /ingot-data/docker/volumes/minio/data:/data \
     -v /ingot-data/docker/volumes/minio/config:/root/.minio \
     quay.io/minio/minio:latest 'server' '/data' '--console-address' ':5001' '-address' ':9000'
