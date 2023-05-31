
INNER_VERSION=0.1.0
MODULE_NAME=minio-api

source ./.local_env

docker login -u ${JY_DOCKER_REGISTRY_USERNAME} -p ${JY_DOCKER_REGISTRY_PASSWORD} docker-registry.wangchao.im
docker build -t docker-registry.wangchao.im/ingot/${MODULE_NAME}:${INNER_VERSION} .
docker push docker-registry.wangchao.im/ingot/${MODULE_NAME}:${INNER_VERSION}
