#!/usr/bin/env bash

source ./.env

mkdir -p ${WORK_DIR}/volumes
chown -R 1000:1000 ${WORK_DIR}/volumes
chmod -R 755 ${WORK_DIR}/volumes

docker compose up -d