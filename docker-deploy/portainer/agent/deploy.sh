#!/usr/bin/env bash

source ./.env

set -e

echo "Deploying Portainer Agent..."

# Stop and remove existing container if exists
docker ps -q --filter name="${CONTEINER_NAME}" | xargs -r docker rm -f
# Remove current images
# docker images -q --filter reference="${PORTAINER_AGENT_IMAGE}:${PORTAINER_AGENT_VERSION}" | xargs -r docker rmi -f
# Pull latest image
# docker pull ${PORTAINER_AGENT_IMAGE}:${PORTAINER_AGENT_VERSION}

# Run Portainer container
CONTAINER_ID=$(docker run -d \
  --name ${CONTEINER_NAME} \
  --network ${DOCKER_NETWORK:-ingot-net} \
  --restart always \
  -p ${PORTAINER_AGENT_PORT}:9001 \
  -e AGENT_SECRET=${PORTAINER_AGENT_SECRET} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ${PORTAINER_AGENT_IMAGE}:${PORTAINER_AGENT_VERSION})

echo "Portainer deployed successfully!"
echo "Container ID: $CONTAINER_ID"
