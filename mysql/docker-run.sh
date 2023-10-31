#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/mysql-8.0.32/volumes


docker run --name mysql-8.0.32 \
 --network ingot-net --ip 172.88.0.10 \
 --restart always \
 -p 3306:3306 \
 -e MYSQL_ROOT_PASSWORD=123456 \
 -v /ingot-data/docker/volumes/mysql-8.0.32/volumes:/var/lib/mysql \
 -d mysql/mysql-server:8.0.32
