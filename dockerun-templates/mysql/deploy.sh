#!/usr/bin/env bash
set -e

echo "Deploying MySQL..."

# Create data directory
mkdir -p ${WORK_DIR}/volumes/data
mkdir -p ${WORK_DIR}/volumes/init
cp ${WORK_DIR}/init/* ${WORK_DIR}/volumes/init/

# Stop and remove existing container if exists
docker stop ${CONTEINER_NAME:-mysql-db} 2>/dev/null || true
docker rm ${CONTEINER_NAME:-mysql-db} 2>/dev/null || true

# Run MySQL container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME:-mysql-db} \
  --restart always \
  --network ${DOCKER_NETWORK:-ingot-net} \
  --ip ${DOCKER_NETWORK_IP:-172.88.0.10} \
  -p ${MYSQL_PORT:-3306}:3306 \
  -e TZ=${TZ} \
  -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  -v ${WORK_DIR}/volumes/data:/var/lib/mysql \
  -v ${WORK_DIR}/volumes/init:/docker-entrypoint-initdb.d \
  ${MYSQL_IMAGE}:${MYSQL_VERSION:-8.0.44})

echo "MySQL deployed successfully!"
echo "Container ID: $CONTAINER_ID"
echo "Root Password: ${MYSQL_ROOT_PASSWORD}"

