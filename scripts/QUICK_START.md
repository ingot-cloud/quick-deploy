# Docker 管理脚本 V2 - 快速开始 🚀

## 5 分钟上手

### 1️⃣ 使用现成示例 (最快)

```bash
cd /path/to/quick-deploy/scripts

# 启动 MySQL
./docker-manager.sh examples-v2/mysql-run.sh start

# 启动 Redis
./docker-manager.sh examples-v2/redis-run.sh start

# 启动 Nginx
./docker-manager.sh examples-v2/nginx-run.sh start

# 查看状态
./docker-manager.sh examples-v2/mysql-run.sh status
```

### 2️⃣ 创建自己的应用

```bash
# 复制模板
cp example.env myapp.env
cp example-run.sh myapp-run.sh

# 修改配置
vi myapp.env
# 至少修改: CONTAINER_NAME, IMAGE_NAME

# 修改执行脚本的配置文件路径
vi myapp-run.sh
# CONFIG_FILE="myapp.env"

# 启动
./docker-manager.sh myapp-run.sh start
```

### 3️⃣ 使用静态 IP (高级)

```bash
# 1. 创建网络
docker network create --subnet=172.20.0.0/16 my-net

# 2. 配置文件添加
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"

# 3. 启动
./docker-manager.sh myapp-run.sh start
```

### 4️⃣ 添加主机名映射

```bash
# 在配置文件中添加
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"

# 启动后容器内可以访问这些主机名
```

## 常用命令

```bash
# 管理命令
./docker-manager.sh myapp-run.sh start      # 启动
./docker-manager.sh myapp-run.sh stop       # 停止
./docker-manager.sh myapp-run.sh restart    # 重启
./docker-manager.sh myapp-run.sh remove     # 删除
./docker-manager.sh myapp-run.sh status     # 状态

# 调试命令
./docker-manager.sh myapp-run.sh logs       # 查看日志
./docker-manager.sh myapp-run.sh logs -f    # 实时日志
./docker-manager.sh myapp-run.sh exec       # 进入容器
./docker-manager.sh myapp-run.sh inspect    # 详细信息
./docker-manager.sh myapp-run.sh stats      # 资源使用
```

## 配置文件最小示例

```bash
# myapp.env
CONTAINER_NAME="myapp"
IMAGE_NAME="nginx:alpine"
PORTS="8080:80"
```

## 完整文档

- **详细指南**: [DOCKER_MANAGER_V2_GUIDE.md](DOCKER_MANAGER_V2_GUIDE.md)
- **应用示例**: [examples-v2/README.md](examples-v2/README.md)
- **对比说明**: [README.md](README.md)

---

**就是这么简单! 🎉**

