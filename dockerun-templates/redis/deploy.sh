#!/usr/bin/env bash
set -e

echo "Deploying Redis..."

# Create data directory
mkdir -p ${WORK_DIR}/volumes/data
mkdir -p ${WORK_DIR}/volumes/conf
cp ${WORK_DIR}/config/redis.conf ${WORK_DIR}/volumes/conf/redis.conf

# Stop and remove existing container if exists
docker stop ${CONTEINER_NAME:-redis} 2>/dev/null || true
docker rm ${CONTEINER_NAME:-redis} 2>/dev/null || true

# Run Redis container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME:-redis} \
  --network ${DOCKER_NETWORK:-ingot-net} \
  --ip ${DOCKER_NETWORK_IP:-172.88.0.90} \
  -p ${REDIS_PORT:-6379}:6379 \
  -v ${WORK_DIR}/volumes/data:/data \
  -v ${WORK_DIR}/volumes/conf/redis.conf:/etc/redis/redis.conf \
  --restart always \
  ${REDIS_IMAGE}:${REDIS_VERSION:-8.2.0} \
  redis-server /etc/redis/redis.conf --appendonly yes)

echo "Redis deployed successfully!"
echo "Container ID: $CONTAINER_ID"