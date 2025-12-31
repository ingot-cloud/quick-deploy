#!/usr/bin/env bash
set -e

source ./mysql.env
CURRENT_DIR=`cd $(dirname $0);pwd -P`

echo "Deploying MySQL..."

# Create data directory
mkdir -p ${WORK_DIR}/volumes/data
mkdir -p ${WORK_DIR}/volumes/init
cp ${CURRENT_DIR}/init/* ${WORK_DIR}/volumes/init/

# Stop and remove existing container if exists
docker stop ${CONTEINER_NAME} 2>/dev/null || true
docker rm ${CONTEINER_NAME} 2>/dev/null || true

# Run MySQL container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME} \
  --restart always \
  --network ${DOCKER_NETWORK} \
  --ip ${DOCKER_NETWORK_IP} \
  -p ${MYSQL_PORT:-3306}:3306 \
  -e TZ=${TZ} \
  -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  -v ${WORK_DIR}/volumes/data:/var/lib/mysql \
  -v ${WORK_DIR}/volumes/init:/docker-entrypoint-initdb.d \
  ${MYSQL_IMAGE}:${MYSQL_VERSION:-8.0.44})

echo "MySQL deployed successfully!"
echo "Container ID: $CONTAINER_ID"
echo "Root Password: ${MYSQL_ROOT_PASSWORD}"

