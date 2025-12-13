#!/usr/bin/env bash

# 控制(管理 Kafka 元数据)服务器地址集群
export CLUSTER_CONTROLLER_SERVERS=${BROKER1_ID}@${BROKER1_NAME}:9093

mkdir -p ${WORK_DIR}/volumes
chown -R 1000:1000 ${WORK_DIR}/volumes
chmod -R 755 ${WORK_DIR}/volumes

docker compose up -d