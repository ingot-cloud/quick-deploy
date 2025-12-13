#!/usr/bin/env bash

source ./env/cluster.env

mkdir -p ${NACOS_VOLUME_ROOT}/nacos1
mkdir -p ${NACOS_VOLUME_ROOT}/nacos2
mkdir -p ${NACOS_VOLUME_ROOT}/nacos3

docker compose -f ./cluster-hostname.yaml up -d