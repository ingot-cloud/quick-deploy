#!/usr/bin/env bash


mkdir -p /ingot-data/docker/volumes/rabbitmq3.7.7


VIRTUAL_HOST=rabbitmq.ingotcloud.top
VIRTUAL_PORT=15672


docker run -d --name rabbitmq3.7.7 \
 --restart always \
 --network ingot-net --ip 172.88.0.80 \
 -p 5671:5671 \
 -p 5672:5672 \
 -v /ingot-data/docker/volumes/rabbitmq3.7.7:/var/lib/rabbitmq \
 -e RABBITMQ_DEFAULT_USER=admin \
 -e RABBITMQ_DEFAULT_PASS=admin \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 rabbitmq:3.7.7-management
