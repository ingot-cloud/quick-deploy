#!/usr/bin/env bash

docker run --name kibana \
 -p 5601:5601 \
 -e "ELASTICSEARCH_HOSTS=http://es01-test:9200" \
 docker.elastic.co/kibana/kibana:7.17.21