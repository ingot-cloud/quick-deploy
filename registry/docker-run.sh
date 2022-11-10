#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/registry/images
mkdir -p /ingot-data/docker/volumes/registry/auth


# 配置htpasswd
cp ${currentPath}/auth/* /ingot-data/docker/volumes/registry/auth


VIRTUAL_HOST=docker-registry.wangchao.im
VIRTUAL_PORT=5000


docker run --name registry \
 --network ingot-net --ip 172.88.0.5 \
 --restart=always \
 --privileged=true \
 -v /data/ingot/docker/volumes/registry/images:/var/lib/registry \
 -v /data/ingot/docker/volumes/registry/auth:/auth \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -e "REGISTRY_AUTH=htpasswd" \
 -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
 -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
 -d registry:latest
