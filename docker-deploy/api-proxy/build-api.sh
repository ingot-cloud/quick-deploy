
INNER_VERSION=1.0.0
MODULE_NAME=proxy-api

# source ./.local_env

docker login -u ${JY_DOCKER_REGISTRY_USERNAME} -p ${JY_DOCKER_REGISTRY_PASSWORD} docker-registry.ingotcloud.top
docker buildx build --platform linux/amd64 -t docker-registry.ingotcloud.top/ingot/${MODULE_NAME}:${INNER_VERSION} --load .
docker push docker-registry.ingotcloud.top/ingot/${MODULE_NAME}:${INNER_VERSION}
