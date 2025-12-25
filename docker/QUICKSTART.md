# Docker 部署快速入门

> 5分钟快速上手Docker在线和离线部署

## 🎯 选择你的场景

### 场景A: 在线安装 (有互联网)

**一行命令搞定:**

```bash
curl -fsSL https://raw.githubusercontent.com/ingot-cloud/quick-deploy/refs/heads/main/docker/install-docker-online.sh | sudo bash
```

或下载后执行:

```bash
wget https://raw.githubusercontent.com/ingot-cloud/quick-deploy/refs/heads/main/docker/install-docker-online.sh
chmod +x install-docker-online.sh
sudo ./install-docker-online.sh
```

### 场景B: 离线安装 (无互联网)

**步骤1: 在联网机器下载**

```bash
# Mac或Linux上
./download-docker-offline.sh
```

交互式选择:
- Docker版本: 27.4.1 (推荐)
- 系统类型: CentOS 或 Ubuntu
- 系统版本: 8 或 22.04
- 架构: amd64 或 arm64

**步骤2: 传输到目标服务器**

```bash
# 打包
tar -czf docker-offline.tar.gz docker-offline-27.4.1-*

# 传输 (选择一种方式)
scp docker-offline.tar.gz root@192.168.1.100:/opt/
# 或使用U盘、FTP等方式
```

**步骤3: 在目标服务器安装**

```bash
# 解压
cd /opt
tar -xzf docker-offline.tar.gz
cd docker-offline-27.4.1-*

# 安装
sudo ./install.sh
```

## ✅ 验证安装

```bash
# 查看版本
docker --version
docker compose version

# 查看信息
docker info

# 运行测试
docker run --rm hello-world
```

## 👤 配置用户权限 (避免sudo)

```bash
# 添加当前用户到docker组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker

# 现在可以不用sudo了
docker ps
```

## 📋 常用命令速查

### 镜像管理

```bash
# 搜索镜像
docker search nginx

# 拉取镜像
docker pull nginx:latest

# 查看本地镜像
docker images

# 删除镜像
docker rmi nginx:latest
```

### 容器管理

```bash
# 运行容器
docker run -d --name mynginx -p 80:80 nginx

# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 停止容器
docker stop mynginx

# 启动容器
docker start mynginx

# 删除容器
docker rm mynginx

# 查看容器日志
docker logs mynginx

# 进入容器
docker exec -it mynginx bash
```

### Docker Compose

```bash
# 启动服务
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f

# 停止服务
docker compose down

# 重启服务
docker compose restart
```

## 🔧 配置调优

### 配置镜像加速 (国内推荐)

编辑 `/etc/docker/daemon.json`:

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

重启Docker:

```bash
sudo systemctl restart docker
```

### 配置资源限制

```bash
# 运行容器时限制资源
docker run -d \
  --name myapp \
  --memory="512m" \
  --cpus="1.0" \
  nginx
```

## 🐛 故障排查

### Docker服务启动失败

```bash
# 查看状态
sudo systemctl status docker

# 查看日志
sudo journalctl -xeu docker

# 重启服务
sudo systemctl restart docker
```

### 权限被拒绝

```bash
# 错误: permission denied while trying to connect to the Docker daemon socket
# 解决: 添加用户到docker组
sudo usermod -aG docker $USER
newgrp docker
```

### 磁盘空间不足

```bash
# 清理未使用的数据
docker system prune -a

# 查看磁盘使用
docker system df
```

### 容器无法启动

```bash
# 查看容器日志
docker logs <container_id>

# 查看详细信息
docker inspect <container_id>

# 交互式调试
docker run -it --entrypoint /bin/bash <image>
```

## 📚 进阶学习

### 创建自定义镜像

创建 `Dockerfile`:

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

构建镜像:

```bash
docker build -t myapp:v1.0 .
docker run -d -p 8080:80 myapp:v1.0
```

### 使用Docker Compose

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: always

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: myapp
    volumes:
      - mysql_data:/var/lib/mysql
    restart: always

volumes:
  mysql_data:
```

运行:

```bash
docker compose up -d
```

## 🔗 有用的链接

- [Docker官方文档](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Dockerfile最佳实践](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose文档](https://docs.docker.com/compose/)

## 💡 最佳实践

1. **使用.dockerignore** - 排除不必要的文件
2. **多阶段构建** - 减小镜像体小
3. **使用非root用户** - 提高安全性
4. **健康检查** - 确保服务可用性
5. **日志管理** - 配置日志轮转
6. **定期更新** - 保持镜像最新
7. **资源限制** - 防止资源耗尽
8. **网络隔离** - 使用自定义网络

## ❓ 需要帮助?

- 查看完整文档: [README.md](README.md)
- 常见问题在README的FAQ部分
- Docker官方社区: https://forums.docker.com/

---
