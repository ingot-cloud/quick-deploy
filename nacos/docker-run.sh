#!/usr/bin/env bash

NACOS_VERSION=2.1.2
CURRENT_PATH=`cd $(dirname $0);pwd -P`

MODE=standalone
SPRING_DATASOURCE_PLATFORM=mysql
MYSQL_SERVICE_HOST=172.88.0.10
MYSQL_SERVICE_DB_NAME=nacos_devtest
MYSQL_SERVICE_PORT=3306
MYSQL_SERVICE_USER=nacos_devtest
MYSQL_SERVICE_PASSWORD=123456
MYSQL_SERVICE_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true

mkdir -p /ingot-data/docker/volumes/nacos-server/logs
cp ${CURRENT_PATH}/custom.properties /ingot-data/docker/volumes/nacos-server

docker run --name nacos-server \
  --network ingot-net --ip 172.88.0.20 \
  --restart always \
  -p 8848:8848 \
  -p 9848:9848 \
  -p 9555:9555 \
  -e MODE=${MODE} \
  -v /ingot-data/docker/volumes/nacos-server/logs:/home/nacos/logs \
  -v /ingot-data/docker/volumes/nacos-server/custom.properties:/home/nacos/init.d/custom.properties \
  -d nacos/nacos-server:${NACOS_VERSION}
