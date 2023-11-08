#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/minio/data
mkdir -p /ingot-data/docker/volumes/minio/config

docker run --name minio \
     --network ingot-net --ip 172.88.0.150 \
     -p 9090:9000 \
     -p 6001:5001 \
     -d --restart=always \
     -e MINIO_ACCESS_KEY=admin \
     -e MINIO_SECRET_KEY=12345678 \
     -v /ingot-data/docker/volumes/minio/data:/data \
     -v /ingot-data/docker/volumes/minio/config:/root/.minio \
     quay.io/minio/minio:latest 'server' '/data' '--console-address' ':5001' '-address' ':9000'
