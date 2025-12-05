#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

source ./.env

# 给 Kafka 用户赋权限, 注意UID和GID，这里用的是1000
mkdir -p ${CLUSTER_BROKER1_VOLUME}
chown -R 1000:1000 ${CLUSTER_BROKER1_VOLUME}
chmod -R 755 ${CLUSTER_BROKER1_VOLUME}

mkdir -p ${CLUSTER_BROKER2_VOLUME}
chown -R 1000:1000 ${CLUSTER_BROKER2_VOLUME}
chmod -R 755 ${CLUSTER_BROKER2_VOLUME}

mkdir -p ${CLUSTER_BROKER3_VOLUME}
chown -R 1000:1000 ${CLUSTER_BROKER3_VOLUME}
chmod -R 755 ${CLUSTER_BROKER3_VOLUME}

docker compose up -d