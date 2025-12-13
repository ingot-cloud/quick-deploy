#!/usr/bin/env bash


mkdir -p /ingot-data/docker/volumes/postgres/pgadmin
mkdir -p /ingot-data/docker/volumes/postgres/data
mkdir -p /ingot-data/docker/volumes/postgres/backups

docker compose up -d