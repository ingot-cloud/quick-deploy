#!/usr/bin/env bash

source ./.env

set -e

echo "Deploying Portainer..."

# Stop and remove existing container if exists
docker ps -q --filter name="${CONTEINER_NAME}" | xargs -r docker rm -f
# Remove current images
# docker images -q --filter reference="${PORTAINER_IMAGE}:${PORTAINER_VERSION}" | xargs -r docker rmi -f
# Pull latest image
# docker pull ${PORTAINER_IMAGE}:${PORTAINER_VERSION}

# Run Portainer container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME} \
  --network ${DOCKER_NETWORK:-ingot-net} \
  --restart always \
  -p ${PORTAINER_PORT}:9000 \
  -e VIRTUAL_HOST=${VIRTUAL_HOST} \
  -e VIRTUAL_PORT=${VIRTUAL_PORT} \
  -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
  -e AGENT_SECRET=${PORTAINER_AGENT_SECRET} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  ${PORTAINER_IMAGE}:${PORTAINER_VERSION})

echo "Portainer deployed successfully!"
echo "Container ID: $CONTAINER_ID"
