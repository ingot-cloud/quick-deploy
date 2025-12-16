# Docker 容器管理脚本使用指南

## 📖 简介

这是一个通用的 Docker 容器管理方案,采用**配置文件驱动**的简洁架构。

### ✨ 核心特点

- **极简使用** - 只需一个配置文件即可启动容器
- **完全灵活** - 支持所有 Docker run 参数
- **易于维护** - 配置清晰,逻辑分离
- **无需适配** - Docker 更新后无需修改脚本

---

## 🏗️ 架构说明

```
配置文件(.env) → docker-run.sh → Docker 容器
                        ↑
                 docker-manager.sh
                 (管理容器生命周期)
```

### 三个核心文件

1. **配置文件 (`.env`)** - 定义所有配置项
2. **执行脚本 (`docker-run.sh`)** - 通用执行脚本(自动调用)
3. **管理脚本 (`docker-manager.sh`)** - 提供管理命令

---

## 🚀 快速开始

### 5 分钟上手

```bash
# 1. 复制配置文件
cp example.env myapp.env

# 2. 编辑配置(最少修改两个参数)
vi myapp.env
# CONTAINER_NAME="myapp"
# IMAGE_NAME="nginx:alpine"

# 3. 启动容器
./docker-manager.sh myapp.env start

# 4. 查看状态
./docker-manager.sh myapp.env status
```

就这么简单!✨

---

## 📋 管理命令

```bash
./docker-manager.sh <配置文件.env> <命令>
```

### 基本命令

| 命令 | 说明 |
|------|------|
| `start` | 启动容器 |
| `stop` | 停止容器 |
| `restart` | 重启容器 |
| `remove` / `rm` | 删除容器 |
| `remove-all` / `rmi` | 删除容器和镜像 |
| `status` | 查看容器状态 |

### 调试命令

| 命令 | 说明 |
|------|------|
| `logs [lines]` | 查看日志 |
| `logs -f` | 实时查看日志 |
| `exec [shell]` | 进入容器 |
| `inspect` | 查看详细信息 |
| `stats` | 查看资源使用 |

### 使用示例

```bash
# 查看日志
./docker-manager.sh myapp.env logs

# 实时日志
./docker-manager.sh myapp.env logs -f

# 进入容器
./docker-manager.sh myapp.env exec

# 进入容器(使用 sh)
./docker-manager.sh myapp.env exec sh
```

---

## ⚙️ 配置文件说明

配置文件是普通的 Bash 环境变量文件。

### 最小配置

```bash
# myapp.env
CONTAINER_NAME="myapp"
IMAGE_NAME="nginx:alpine"
PORTS="8080:80"
```

### 完整配置示例

```bash
# ==================== 基本配置 ====================
CONTAINER_NAME="myapp"
IMAGE_NAME="nginx:alpine"
CONTAINER_HOSTNAME="myapp.local"
RESTART_POLICY="unless-stopped"

# ==================== 网络配置 ====================
NETWORK_MODE="bridge"
NETWORK_NAME="my-network"      # 自定义网络
CONTAINER_IP="172.20.0.100"    # 静态 IP

# ==================== 端口映射 ====================
PORTS="8080:80 8443:443"

# ==================== 环境变量 ====================
ENV_VARS="
DATABASE_HOST=mysql
DATABASE_PORT=3306
APP_ENV=production
TZ=Asia/Shanghai
"

# ==================== 卷挂载 ====================
VOLUMES="
/data/myapp:/app/data
/logs/myapp:/app/logs
"

NAMED_VOLUMES="
myapp-data:/app/data
"

# ==================== 主机名映射 ====================
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"

# ==================== DNS 配置 ====================
DNS_SERVERS="8.8.8.8 8.8.4.4"
DNS_SEARCH="example.com"

# ==================== 资源限制 ====================
CPU_LIMIT="2.0"
MEMORY_LIMIT="1g"

# ==================== 健康检查 ====================
HEALTH_CHECK_ENABLED="true"
HEALTH_CHECK_CMD="curl -f http://localhost/ || exit 1"
HEALTH_CHECK_INTERVAL="30s"
HEALTH_CHECK_TIMEOUT="10s"
HEALTH_CHECK_RETRIES="3"

# ==================== 日志配置 ====================
LOG_DRIVER="json-file"
LOG_MAX_SIZE="10m"
LOG_MAX_FILE="3"

# ==================== 安全配置 ====================
RUN_AS_USER="1000:1000"
CAP_ADD="NET_ADMIN"
CAP_DROP="MKNOD"

# ==================== 设备映射 ====================
DEVICES="
/dev/video0:/dev/video0:rwm
"

# ==================== 内核参数 ====================
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
"

# ==================== 其他配置 ====================
ULIMIT_NOFILE="65536"
LABELS="
app=myapp
version=1.0.0
"
```

完整参数列表请查看 [example.env](example.env)。

---

## 💡 实际应用示例

### 示例 1: MySQL 数据库

**配置文件: `mysql.env`**

```bash
CONTAINER_NAME="mysql-db"
IMAGE_NAME="mysql:8.0"
RESTART_POLICY="unless-stopped"

# 网络配置
NETWORK_NAME="backend-net"
CONTAINER_IP="172.20.0.10"

# 端口
PORTS="3306:3306"

# 环境变量
ENV_VARS="
MYSQL_ROOT_PASSWORD=YourPassword123!
MYSQL_DATABASE=myapp_db
MYSQL_USER=myapp_user
MYSQL_PASSWORD=MyApp_Pass123!
TZ=Asia/Shanghai
"

# 数据持久化
NAMED_VOLUMES="
mysql-data:/var/lib/mysql
"

# 资源限制
CPU_LIMIT="2.0"
MEMORY_LIMIT="2g"

# 健康检查
HEALTH_CHECK_ENABLED="true"
HEALTH_CHECK_CMD="mysqladmin ping -h localhost -u root -pYourPassword123!"
```

**使用:**

```bash
# 创建网络(首次)
docker network create --subnet=172.20.0.0/16 backend-net

# 启动
./docker-manager.sh mysql.env start

# 查看日志
./docker-manager.sh mysql.env logs -f
```

### 示例 2: Nginx 反向代理

**配置文件: `nginx.env`**

```bash
CONTAINER_NAME="nginx-proxy"
IMAGE_NAME="nginx:alpine"

PORTS="80:80 443:443"

# 挂载配置和网站
VOLUMES="
/data/nginx/conf.d:/etc/nginx/conf.d:ro
/data/nginx/html:/usr/share/nginx/html:ro
/data/nginx/logs:/var/log/nginx
"

# 后端服务映射
EXTRA_HOSTS="
172.20.0.10:backend-api.local
172.20.0.11:backend-db.local
"

# 健康检查
HEALTH_CHECK_ENABLED="true"
HEALTH_CHECK_CMD="curl -f http://localhost/ || exit 1"
```

### 示例 3: Redis 缓存

**配置文件: `redis.env`**

```bash
CONTAINER_NAME="redis-cache"
IMAGE_NAME="redis:7-alpine"
PORTS="6379:6379"

# 数据持久化
NAMED_VOLUMES="
redis-data:/data
"

# 配置文件(可选)
VOLUMES="
/data/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
"

# 启动命令
CONTAINER_CMD="redis-server /usr/local/etc/redis/redis.conf"

# 资源限制
CPU_LIMIT="1.0"
MEMORY_LIMIT="512m"
```

---

## 🌟 高级功能

### 1. 使用静态 IP

```bash
# 创建自定义网络
docker network create --subnet=172.20.0.0/16 backend-net

# 配置文件
NETWORK_NAME="backend-net"
CONTAINER_IP="172.20.0.10"
```

### 2. 主机名映射

用于反向代理、微服务通信等场景:

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
10.0.0.5:external-api.com
"
```

容器内可以通过主机名访问:

```bash
ping database.local
curl http://cache.local:6379
```

### 3. 设备映射

映射 GPU、摄像头等设备:

```bash
DEVICES="
/dev/video0:/dev/video0:rwm
/dev/nvidia0:/dev/nvidia0:rwm
"
```

### 4. 内核参数调优

```bash
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=8192
"
```

### 5. Linux Capabilities

```bash
# 添加能力
CAP_ADD="NET_ADMIN SYS_TIME"

# 删除能力
CAP_DROP="MKNOD"
```

### 6. 资源限制

```bash
# CPU 限制
CPU_LIMIT="2.0"          # 2 核
CPU_SHARES="1024"        # CPU 份额

# 内存限制
MEMORY_LIMIT="2g"        # 2GB
MEMORY_RESERVATION="1g"  # 预留 1GB

# 文件描述符
ULIMIT_NOFILE="65536"

# 进程数
ULIMIT_NPROC="8192"
```

---

## 🔧 自定义执行脚本

99% 的场景只需配置文件即可。如需特殊逻辑:

```bash
# 1. 复制通用脚本
cp docker-run.sh myapp-custom-run.sh

# 2. 修改配置文件路径
vi myapp-custom-run.sh
# CONFIG_FILE="myapp.env"

# 3. 添加自定义逻辑
# 例如:启动前创建网络、动态生成配置等

# 4. 使用自定义脚本
./docker-manager.sh myapp-custom-run.sh start
```

---

## 🎨 最佳实践

### 1. 文件组织

```
project/
├── docker-manager.sh       # 管理脚本
├── docker-run.sh          # 通用执行脚本
├── configs/               # 配置文件目录
│   ├── mysql-dev.env
│   ├── mysql-prod.env
│   ├── redis-dev.env
│   └── redis-prod.env
└── data/                  # 数据目录
    ├── mysql/
    └── redis/
```

### 2. 命名规范

```bash
# 配置文件命名
<服务名>-<环境>.env

# 示例
mysql-dev.env       → CONTAINER_NAME="mysql-dev"
mysql-test.env      → CONTAINER_NAME="mysql-test"
mysql-prod.env      → CONTAINER_NAME="mysql-prod"
```

### 3. 环境隔离

```bash
# 开发环境
./docker-manager.sh configs/myapp-dev.env start

# 生产环境
./docker-manager.sh configs/myapp-prod.env start
```

### 4. 版本控制

```bash
# 提交配置文件
git add configs/*.env
git commit -m "Add application configurations"

# 不要提交敏感信息
echo "*.env" >> .gitignore  # 如果包含密码
```

### 5. 安全建议

- 生产环境使用非 root 用户: `RUN_AS_USER="1000:1000"`
- 设置资源限制防止占用过多资源
- 使用只读挂载: `/data:/app/data:ro`
- 定期更新镜像版本
- 敏感信息使用 Docker Secrets 或环境变量

---

## ❓ 常见问题

### Q1: 如何查看配置是否正确?

```bash
# 测试加载配置文件
source myapp.env && echo "配置正确"

# 查看会执行的命令(启动后查看日志)
./docker-manager.sh myapp.env start
```

### Q2: 容器启动失败怎么办?

```bash
# 1. 查看日志
./docker-manager.sh myapp.env logs

# 2. 检查镜像
docker images | grep myapp

# 3. 检查端口占用
netstat -tlnp | grep 8080

# 4. 检查网络
docker network ls
```

### Q3: 如何更新容器?

```bash
# 1. 拉取新镜像
docker pull new-image:tag

# 2. 更新配置文件中的镜像
vi myapp.env
# IMAGE_NAME="new-image:tag"

# 3. 重新创建容器
./docker-manager.sh myapp.env stop
./docker-manager.sh myapp.env remove
./docker-manager.sh myapp.env start
```

### Q4: 如何批量管理容器?

```bash
# 批量启动
for env in configs/*.env; do
    ./docker-manager.sh "$env" start
done

# 批量停止
for env in configs/*.env; do
    ./docker-manager.sh "$env" stop
done
```

### Q5: 配置文件可以包含哪些参数?

查看 `example.env` 文件,包含所有支持的参数及说明。

---

## 📚 参考资料

- [快速开始](QUICK_START.md) - 3 分钟上手
- [配置模板](example.env) - 完整参数说明
- [应用示例](examples/README.md) - MySQL、Redis、Nginx 等
- [Docker 官方文档](https://docs.docker.com/)

---

**开始使用吧! 🚀**
