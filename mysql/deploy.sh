#!/usr/bin/env bash
set -e

echo "Deploying MySQL..."

# Create data directory
mkdir -p ${WORK_DIR}/volumes/data

# Stop and remove existing container if exists
docker stop ${CONTEINER_NAME} 2>/dev/null || true
docker rm ${CONTEINER_NAME} 2>/dev/null || true

# Run MySQL container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME} \
  --network ${DOCKER_NETWORK} --ip ${DOCKER_NETWORK_IP} \
  -p ${MYSQL_PORT:-3306}:3306 \
  -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  -v ${WORK_DIR}/volumes/data:/var/lib/mysql \
  --restart unless-stopped \
  ${MYSQL_IMAGE}:${MYSQL_VERSION:-8.0.44})

echo "MySQL deployed successfully!"
echo "Container ID: $CONTAINER_ID"
echo "Root Password: ${MYSQL_ROOT_PASSWORD}"

