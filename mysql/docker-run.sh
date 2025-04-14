#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`
MYSQL_IMAGE=mysql:8.0.41 # mysql/mysql-server:8.0.32
MYSQL_ROOT_PASSWORD=123456
MYSQL_VALUME_PATH=/ingot-data/docker/volumes/mysql/volumes

mkdir -p ${MYSQL_VALUME_PATH}

docker run --name mysql-8.0.32 \
 --network ingot-net --ip 172.88.0.10 \
 -d --restart always \
 -p 3306:3306 \
 -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
 -v ${MYSQL_VALUME_PATH}:/var/lib/mysql \
 ${MYSQL_IMAGE}
