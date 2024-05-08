#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

mkdir -p /ingot-data/docker/volumes/es/
cp ${currentPath}/elastic-certificates.p12 /ingot-data/docker/volumes/es/elastic-certificates.p12
cp ${currentPath}/elasticsearch.yml /ingot-data/docker/volumes/es/elasticsearch.yml

docker run --name elasticsearch \
 -d --restart=always \
 -p 9200:9200 \
 -p 9300:9300 \
 -e "discovery.type=single-node" \
 -v /ingot-data/docker/volumes/es/elastic-certificates.p12:/usr/share/elasticsearch/config/elastic-certificates.p12 \
 -v /ingot-data/docker/volumes/es/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
 docker.elastic.co/elasticsearch/elasticsearch:7.17.21
