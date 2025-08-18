#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/redis/conf
mkdir -p /ingot-data/docker/volumes/redis/data
cp ${currentPath}/redis.conf /ingot-data/docker/volumes/redis/conf

docker run --name redis \
 --restart always \
 --network ingot-net --ip 172.88.0.90 \
 -p 6379:6379 \
 -v /ingot-data/docker/volumes/redis/conf/redis.conf:/etc/redis/redis.conf \
 -v /ingot-data/docker/volumes/redis/data:/data \
 -d docker-registry.ingotcloud.top/redis:8.2.0 redis-server /etc/redis/redis.conf --appendonly yes