#!/usr/bin/env bash

NACOS_VERSION=v2.1.2
CURRENT_PATH=`cd $(dirname $0);pwd -P`

# 系统启动方式: 集群/单机 cluster/standalone 默认 cluster
MODE=standalone
# Nacos 运行端口
NACOS_SERVER_PORT=8848
SPRING_DATASOURCE_PLATFORM=mysql
MYSQL_SERVICE_HOST=172.88.0.10
MYSQL_SERVICE_DB_NAME=ingot_nacos_config
MYSQL_SERVICE_PORT=3306
MYSQL_SERVICE_USER=nacos_dev
MYSQL_SERVICE_PASSWORD=123456
MYSQL_SERVICE_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true

# 是否开启权限系统
NACOS_AUTH_ENABLE=true
# 权限系统类型选择,目前只支持nacos类型
NACOS_AUTH_SYSTEM_TYPE=nacos
# token 失效时间
NACOS_AUTH_TOKEN_EXPIRE_SECONDS=7200
# token 至少32位，base64  ingotingotingotingotingotingotingot
NACOS_AUTH_TOKEN=aW5nb3RpbmdvdGluZ290aW5nb3RpbmdvdGluZ290aW5nb3Q=
# nacos.core.auth.server.identity.key
NACOS_AUTH_IDENTITY_KEY=ingot
# nacos.core.auth.server.identity.value
NACOS_AUTH_IDENTITY_VALUE=ingot


mkdir -p /ingot-data/docker/volumes/nacos-server/logs
cp ${CURRENT_PATH}/custom.properties /ingot-data/docker/volumes/nacos-server

VIRTUAL_HOST=nacos.ingotcloud.top
VIRTUAL_PORT=8848

docker run --name nacos-server \
  --network ingot-net --ip 172.88.0.20 \
  --restart always \
  -p 8848:8848 \
  -p 9848:9848 \
  -p 9555:9555 \
  -e MODE=${MODE} \
  -e NACOS_SERVER_PORT=${NACOS_SERVER_PORT} \
  -e SPRING_DATASOURCE_PLATFORM=${SPRING_DATASOURCE_PLATFORM} \
  -e MYSQL_SERVICE_HOST=${MYSQL_SERVICE_HOST} \
  -e MYSQL_SERVICE_DB_NAME=${MYSQL_SERVICE_DB_NAME} \
  -e MYSQL_SERVICE_PORT=${MYSQL_SERVICE_PORT} \
  -e MYSQL_SERVICE_USER=${MYSQL_SERVICE_USER} \
  -e MYSQL_SERVICE_PASSWORD=${MYSQL_SERVICE_PASSWORD} \
  -e MYSQL_SERVICE_DB_PARAM=${MYSQL_SERVICE_DB_PARAM} \
  -e NACOS_AUTH_ENABLE=${NACOS_AUTH_ENABLE} \
  -e NACOS_AUTH_SYSTEM_TYPE=${NACOS_AUTH_SYSTEM_TYPE} \
  -e NACOS_AUTH_TOKEN_EXPIRE_SECONDS=${NACOS_AUTH_TOKEN_EXPIRE_SECONDS} \
  -e NACOS_AUTH_TOKEN=${NACOS_AUTH_TOKEN} \
  -e NACOS_AUTH_IDENTITY_KEY=${NACOS_AUTH_IDENTITY_KEY} \
  -e NACOS_AUTH_IDENTITY_VALUE=${NACOS_AUTH_IDENTITY_VALUE} \
  -e VIRTUAL_HOST=${VIRTUAL_HOST} \
  -e VIRTUAL_PORT=${VIRTUAL_PORT} \
  -v /ingot-data/docker/volumes/nacos-server/logs:/home/nacos/logs \
  -v /ingot-data/docker/volumes/nacos-server/custom.properties:/home/nacos/init.d/custom.properties \
  -d nacos/nacos-server:${NACOS_VERSION}
