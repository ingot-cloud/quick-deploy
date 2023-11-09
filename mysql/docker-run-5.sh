#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/mysql-5.7/volumes


docker run --name mysql-5.7 \
 --network ingot-net --ip 172.88.0.10 \
 --restart always \
 -p 3306:3306 \
 -e MYSQL_ROOT_PASSWORD=123456 \
 -v /ingot-data/docker/volumes/mysql-5.7/volumes:/var/lib/mysql \
 -d mysql:5.7