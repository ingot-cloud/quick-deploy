#!/usr/bin/env bash

VERSION=2.27.9
IMAGE_NAME=portainer/portainer-ce
SERVICE_NAME=portainer

# 停止运行当前容器
docker ps -q --filter name="${SERVICE_NAME}" | xargs -r docker rm -f
# 删除当前镜像
docker images -q --filter reference="${imageName}" | xargs -r docker rmi -f

docker run -d --name portainer \
 --network ingot-net \
 --restart always \
 -p 9000:9000 \
 -e AGENT_SECRET=123456 \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v portainer_data:/data \
 portainer/portainer-ce:${VERSION}
