#!/usr/bin/env bash
set -e

source ./.env
CURRENT_DIR=`cd $(dirname $0);pwd -P`

echo "Deploying XXL Job Admin..."

# Create directory
mkdir -p ${WORK_DIR}/volumes/logs

# Run container
CONTAINER_ID=$(docker compose up -d xxl-job-admin)

echo "XXL Job Admin deployed successfully!"
echo "Container ID: $CONTAINER_ID"

