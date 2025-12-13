#!/bin/bash


echo "创建数据目录..."
sudo mkdir -p /ingot-data/docker/volumes/windows

echo "启动服务..."
docker compose up -d