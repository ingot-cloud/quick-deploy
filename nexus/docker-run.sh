#!/usr/bin/env bash


mkdir -p /ingot-data/docker/volumes/nexus3/data

# 启动nexus，如果没有postgres，那么需要都启动
docker compose up nexus -d