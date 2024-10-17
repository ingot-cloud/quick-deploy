#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

mkdir -p /ingot-data/docker/volumes/kafka/broker1
mkdir -p /ingot-data/docker/volumes/kafka/broker2
mkdir -p /ingot-data/docker/volumes/kafka/broker3

docker compose up -d