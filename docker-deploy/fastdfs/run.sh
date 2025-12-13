#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

mkdir -p /ingot-data/docker/volumes/fastdfs/storage/conf
cp -rf ${currentPath}/conf/* /ingot-data/docker/volumes/fastdfs/storage/conf

mkdir -p /ingot-data/docker/volumes/fastdfs/storage/data

mkdir -p /ingot-data/docker/volumes/fastdfs/storage/nginx
cp -rf ${currentPath}/nginx_conf.d/* /ingot-data/docker/volumes/fastdfs/storage/nginx

mkdir -p /ingot-data/docker/volumes/fastdfs/tracker/conf
cp -rf ${currentPath}/conf/* /ingot-data/docker/volumes/fastdfs/tracker/conf

mkdir -p /ingot-data/docker/volumes/fastdfs/tracker/data

docker compose up -d