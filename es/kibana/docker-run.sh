#!/usr/bin/env bash

docker run --name kibana \
 -d --restart=always \
 --network ingot-net --ip 172.88.0.130  \
 -p 5601:5601 \
 -v /ingot-data/docker/volumes/kibana/config:/usr/share/kibana/config \
 docker.elastic.co/kibana/kibana:7.17.21