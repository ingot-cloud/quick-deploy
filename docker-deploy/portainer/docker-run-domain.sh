#!/usr/bin/env bash


VERSION=2.33.5
IMAGE_NAME=docker-registry.ingotcloud.top/portainer/portainer-ce
SERVICE_NAME=portainer

VIRTUAL_HOST=portainer.ingotcloud.top
VIRTUAL_PORT=9000

# 停止运行当前容器
docker ps -q --filter name="${SERVICE_NAME}" | xargs -r docker rm -f
# 删除当前镜像
docker images -q --filter reference="${IMAGE_NAME}" | xargs -r docker rmi -f
# 拉取最新镜像
docker pull ${IMAGE_NAME}

docker run -d --name portainer \
 --network ingot-net \
 --restart always \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -e AGENT_SECRET=123456 \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v portainer_data:/data \
 ${IMAGE_NAME}:${VERSION}
