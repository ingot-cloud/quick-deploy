#!/usr/bin/env bash


mkdir -p /ingot-data/docker/volumes/rabbitmq3.7.7


docker run -d --name rabbitmq3.7.7 \
 --restart always \
 --network ingot-net --ip 172.88.0.80 \
 -p 5671:5671 \
 -p 5672:5672 \
 -v /ingot-data/docker/volumes/rabbitmq3.7.7:/var/lib/rabbitmq \
 -e RABBITMQ_DEFAULT_USER=admin \
 -e RABBITMQ_DEFAULT_PASS=admin \
 rabbitmq:3.7.7-management
