#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/registry/images
mkdir -p /ingot-data/docker/volumes/registry/auth
mkdir -p /ingot-data/docker/volumes/registry/config


# 配置htpasswd
cp ${currentPath}/auth/* /ingot-data/docker/volumes/registry/auth
cp ${currentPath}/default.yml /ingot-data/docker/volumes/registry/config


VIRTUAL_HOST=docker-registry.ingotcloud.top
VIRTUAL_PORT=5000


docker run --name registry \
 --network ingot-net --ip 172.88.0.5 \
 --restart=always \
 --privileged=true \
 -v /ingot-data/docker/volumes/registry/config/default.yml:/etc/docker/registry/config.yml \
 -v /ingot-data/docker/volumes/registry/images:/var/lib/registry \
 -v /ingot-data/docker/volumes/registry/auth:/auth \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -e "REGISTRY_AUTH=htpasswd" \
 -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
 -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
 -d registry:latest
