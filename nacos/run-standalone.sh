#!/usr/bin/env bash

source ./env/standalone.env

set -e

echo "Deploying Nacos Standard..."

# Create data directory
mkdir -p ${WORK_DIR}/volumes/logs

# Stop and remove existing container if exists
docker stop ${CONTEINER_NAME} 2>/dev/null || true
docker rm ${CONTEINER_NAME} 2>/dev/null || true

# Run Nacos container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME} \
  --network ${DOCKER_NETWORK} \
  --restart always \
  -p ${NACOS_CLIENT_PORT}:8080 \
  -p ${NACOS_SERVER_PORT}:8848 \
  -p ${NACOS_METRICS_PORT}:9848 \
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
  -v ${WORK_DIR}/volumes/logs:/home/nacos/logs \
  ${NACOS_IMAGE}:${NACOS_VERSION})

echo "Nacos Standard deployed successfully!"
echo "Container ID: $CONTAINER_ID"