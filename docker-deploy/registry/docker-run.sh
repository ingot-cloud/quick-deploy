#!/usr/bin/env bash

source ./.env

CURRENT_DIR=`cd $(dirname $0);pwd -P`

mkdir -p ${WORK_DIR}/volumes/images
mkdir -p ${WORK_DIR}/volumes/auth
mkdir -p ${WORK_DIR}/volumes/config


# 配置htpasswd
cp ${CURRENT_DIR}/auth/* ${WORK_DIR}/volumes/auth
cp ${CURRENT_DIR}/config.yml ${WORK_DIR}/volumes/config

docker run --name registry \
 --network ingot-net \
 --restart=always \
 --privileged=true \
 -v ${WORK_DIR}/volumes/config/config.yml:/etc/distribution/config.yml \
 -v ${WORK_DIR}/volumes/images:/var/lib/registry \
 -v ${WORK_DIR}/volumes/auth:/auth \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -d docker-registry.ingotcloud.top/registry:3.0.0
