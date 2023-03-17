#!/usr/bin/env bash


VIRTUAL_HOST=portainer.wangchao.im
VIRTUAL_PORT=9000


docker run -d --name portainer \
 --network ingot-net \
 --restart always \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -e AGENT_SECRET=123456 \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v portainer_data:/data \
 portainer/portainer-ce
