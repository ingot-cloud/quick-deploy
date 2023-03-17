#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/redis-4.0.10/conf
mkdir -p /ingot-data/docker/volumes/redis-4.0.10/data
cp ${currentPath}/redis-4.0.10.conf /ingot-data/docker/volumes/redis-4.0.10/conf


docker run --name redis \
 --restart always \
 --network ingot-net --ip 172.88.0.90 \
 -p 6379:6379 \
 -v /ingot-data/docker/volumes/redis-4.0.10/conf/redis-4.0.10.conf:/etc/redis/redis.conf \
 -v /ingot-data/docker/volumes/redis-4.0.10/data:/data \
 -d redis:4.0.10 redis-server /etc/redis/redis.conf --appendonly yes
