# 使用示例

在联网机器上生成离线包（交互式）：
```shell
./offline-docker-builder.sh
# 会提示 Docker version (default 28.4.0)、arch、mode、os、os-version、compose...
```

或直接非交互方式：
```shell
./offline-docker-builder.sh 28.4.0 amd64 --mode rpm-only --os centos --os-version 8 --compose-version v5.0.0
```

把生成的文件夹复制到目标机器上（例如 /opt/docker-offline-28.4.0-amd64），在目标机上运行：
```shell
sudo /install-offline.sh /opt/docker-offline-28.4.0-amd64
```