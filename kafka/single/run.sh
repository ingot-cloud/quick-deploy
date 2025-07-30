#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

mkdir -p /ingot-data/docker/volumes/kafka/broker

docker compose up -d