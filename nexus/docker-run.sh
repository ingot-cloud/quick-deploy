#!/usr/bin/env bash


VIRTUAL_HOST=域名
VIRTUAL_PORT=8081


docker run -d --name nexus3 \
 --network ingot-net \
 --restart always \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -v nexus-data:/nexus-data \
 sonatype/nexus3
