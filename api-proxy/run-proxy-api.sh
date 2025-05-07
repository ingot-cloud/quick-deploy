#!/usr/bin/env bash

VERSION=0.1.0
SERVICE_NAME=proxy-api-${VERSION}
IMAGE_NAME=docker-registry.ingotcloud.top/ingot/proxy-api:${VERSION}

VIRTUAL_HOST=proxy-api.ingotcloud.top
VIRTUAL_PORT=3000

# 停止运行当前容器
docker ps -q --filter name="${SERVICE_NAME}" | xargs -r docker rm -f
# 删除当前镜像
docker images -q --filter reference="${IMAGE_NAME}" | xargs -r docker rmi -f
# 拉取最新镜像
docker pull ${IMAGE_NAME}
# run
docker run -d --name ${SERVICE_NAME} --restart always \
    --network ingot-net \
    -e VIRTUAL_HOST=${VIRTUAL_HOST} \
    -e VIRTUAL_PORT=${VIRTUAL_PORT} \
    -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
    ${IMAGE_NAME}
