#!/usr/bin/env bash


currentPath=`cd $(dirname $0);pwd -P`

mkdir -p /ingot-data/docker/volumes/gitlab-runner

docker run -d --name gitlab-runner --restart always \
  -v /ingot-data/docker/volumes/gitlab-runner:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
