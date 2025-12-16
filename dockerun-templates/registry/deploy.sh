#!/usr/bin/env bash
set -e

# 部署前，请先阅读README.md

echo "Deploying Registry..."

mkdir -p ${WORK_DIR}/volumes/images
mkdir -p ${WORK_DIR}/volumes/auth
mkdir -p ${WORK_DIR}/volumes/config

# 配置htpasswd
cp ${WORK_DIR}/auth/* ${WORK_DIR}/volumes/auth
cp ${WORK_DIR}/config/config.yml ${WORK_DIR}/volumes/config/config.yml


docker run --name ${CONTEINER_NAME} \
 --network ${DOCKER_NETWORK:-ingot-net} \
 --restart=always \
 --privileged=true \
 -p ${REGISTRY_PORT:-5000}:5000 \
 -e OTEL_TRACES_EXPORTER=none \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -v ${WORK_DIR}/volumes/auth:/auth \
 -v ${WORK_DIR}/volumes/config/config.yml:/etc/distribution/config.yml \
 -d ${REGISTRY_IMAGE}:${REGISTRY_VERSION}
