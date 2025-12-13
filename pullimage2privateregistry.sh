#!/usr/bin/env bash

# 拉取镜像并且推送到私有仓库,保持多架构
IMAGE=nacos/nacos-server
TAG=v3.1.1
PRIVATE_REGISTRY=docker-registry.ingotcloud.top

# 1. 分别拉取两种架构的镜像并标记
docker pull --platform linux/amd64 $IMAGE:$TAG
docker tag $IMAGE:$TAG $PRIVATE_REGISTRY/$IMAGE:$TAG-amd64
docker pull --platform linux/arm64 $IMAGE:$TAG
docker tag $IMAGE:$TAG $PRIVATE_REGISTRY/$IMAGE:$TAG-arm64

# 2. 推送单架构镜像到私有仓库
docker push $PRIVATE_REGISTRY/$IMAGE:$TAG-amd64
docker push $PRIVATE_REGISTRY/$IMAGE:$TAG-arm64

# 3. 创建并推送多架构 Manifest
docker manifest create $PRIVATE_REGISTRY/$IMAGE:$TAG \
  --amend $PRIVATE_REGISTRY/$IMAGE:$TAG-amd64 \
  --amend $PRIVATE_REGISTRY/$IMAGE:$TAG-arm64
docker manifest push $PRIVATE_REGISTRY/$IMAGE:$TAG

# 4. 清理本地临时镜像（可选）
# docker rmi $PRIVATE_REGISTRY/$IMAGE:$TAG-amd64 $PRIVATE_REGISTRY/$IMAGE:$TAG-arm64