#!/usr/bin/env bash

docker volume create n8n_data

docker run -dt --restart always \
 --name n8n \
 -p 5678:5678 \
 -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false \
 -e N8N_HOST=localhost \
 -e N8N_PORT=5678 \
 -v n8n_data:/home/node/.n8n \
 n8nio/n8n:1.94.1
