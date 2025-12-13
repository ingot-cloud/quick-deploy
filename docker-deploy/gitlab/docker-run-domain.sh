#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`


mkdir -p /ingot-data/docker/volumes/gitlab/etc
mkdir -p /ingot-data/docker/volumes/gitlab/log
mkdir -p /ingot-data/docker/volumes/gitlab/opt

VIRTUAL_HOST=gitlab.ingotcloud.top
VIRTUAL_PORT=80

# 80,443,22
docker run --name gitlab \
  --hostname ${VIRTUAL_HOST} \
  --network ingot-net --ip 172.88.0.200 \
  -d --restart=always \
  --privileged=true \
  -e VIRTUAL_HOST=${VIRTUAL_HOST} \
  -e VIRTUAL_PORT=${VIRTUAL_PORT} \
  -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
  -v /ingot-data/docker/volumes/gitlab/etc:/etc/gitlab \
  -v /ingot-data/docker/volumes/gitlab/log:/var/log/gitlab \
  -v /ingot-data/docker/volumes/gitlab/opt:/var/opt/gitlab \
  gitlab/gitlab-ce
