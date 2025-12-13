#!/usr/bin/env bash

source ./.env

set -e

echo "Deploying Nacos Cluster..."

# Create data directory
mkdir -p ${WORK_DIR}/${NACOS1_CONTEINER_NAME}/volumes/logs
mkdir -p ${WORK_DIR}/${NACOS2_CONTEINER_NAME}/volumes/logs
mkdir -p ${WORK_DIR}/${NACOS3_CONTEINER_NAME}/volumes/logs

# Run Nacos container
docker compose -f ./cluster-hostname.yaml up -d

echo "Nacos Cluster deployed successfully!"