# Docker 容器管理脚本 V2 使用指南

## 📖 简介

这是一个全新设计的 Docker 容器管理方案,采用**配置文件 + 执行脚本**分离的架构,相比 V1 版本有以下优势:

### ✨ 核心优势

- **完全灵活** - 在执行脚本中可以使用任何 docker run 参数
- **易于维护** - 配置和命令分离,清晰明了
- **无需适配** - Docker 更新后无需修改管理脚本
- **复用简单** - 复制配置文件和执行脚本即可

### 🆚 与 V1 的区别

| 特性 | V1 (docker-run-template.sh) | V2 (docker-manager.sh) |
|------|----------------------------|------------------------|
| 架构 | 单脚本+配置文件 | 管理脚本+配置文件+执行脚本 |
| 参数支持 | 预定义的参数 | 任意 docker run 参数 |
| 扩展性 | 需要修改模板脚本 | 直接在执行脚本中添加 |
| `--ip` 支持 | ❌ 不支持 | ✅ 支持 |
| `--add-host` 支持 | ❌ 不支持 | ✅ 支持 |
| `--device` 支持 | ❌ 不支持 | ✅ 支持 |
| `--sysctl` 支持 | ❌ 不支持 | ✅ 支持 |
| `--ulimit` 支持 | ❌ 不支持 | ✅ 支持 |

---

## 🏗️ 架构说明

新方案由三部分组成:

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker 管理架构 V2                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. 配置文件 (.env)                                         │
│     ├─ 定义环境变量                                         │
│     ├─ 容器基本配置                                         │
│     └─ 资源限制等                                          │
│                                                              │
│  2. 执行脚本 (-run.sh)                                      │
│     ├─ 加载配置文件                                         │
│     ├─ 编写 docker run 命令                                 │
│     └─ 可使用任意 docker 参数                               │
│                                                              │
│  3. 管理脚本 (docker-manager.sh)                            │
│     ├─ 提供 start/stop/restart 等命令                       │
│     ├─ 容器生命周期管理                                     │
│     └─ 日志查看、进入容器等                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 工作流程

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│ 配置文件.env │ ───> │ 执行脚本.sh  │ ───> │ Docker 容器  │
│              │       │              │       │              │
│ - 变量定义   │       │ - 构建命令   │       │ - 运行中     │
│ - 基本配置   │       │ - 执行启动   │       │              │
└──────────────┘       └──────────────┘       └──────────────┘
       ↓                      ↓                       ↓
       └──────────────────────┴───────────────────────┘
                              ↓
                   ┌──────────────────┐
                   │ docker-manager.sh│
                   │                  │
                   │ - 启动/停止      │
                   │ - 重启/删除      │
                   │ - 查看日志       │
                   │ - 进入容器       │
                   └──────────────────┘
```

---

## 🚀 快速开始

### 方式 1: 使用示例快速部署

```bash
# 进入 scripts 目录
cd scripts

# 1. 复制示例文件
cp example.env myapp.env
cp example-run.sh myapp-run.sh

# 2. 编辑配置文件
vi myapp.env

# 3. 编辑执行脚本（如果需要添加特殊参数）
vi myapp-run.sh

# 4. 启动容器
./docker-manager.sh myapp-run.sh start
```

### 方式 2: 使用现成的应用示例

```bash
cd scripts/examples-v2

# MySQL 示例
./docker-manager.sh mysql-run.sh start

# Redis 示例  
./docker-manager.sh redis-run.sh start

# Nginx 示例
./docker-manager.sh nginx-run.sh start

# 高级应用示例（展示 --ip、--add-host 等用法）
./docker-manager.sh advanced-app-run.sh start
```

---

## 📝 详细使用步骤

### 第一步: 创建配置文件

配置文件定义了容器运行所需的所有变量。

```bash
# 方式 1: 复制示例
cp example.env myapp.env

# 方式 2: 复制现有应用的配置
cp examples-v2/mysql.env myapp.env
```

编辑配置文件 `myapp.env`:

```bash
# 基本配置
CONTAINER_NAME="myapp"
IMAGE_NAME="nginx:latest"
RESTART_POLICY="unless-stopped"

# 网络配置
NETWORK_NAME="my-network"
CONTAINER_IP="172.20.0.100"  # 静态 IP

# 端口映射
PORTS="8080:80 8443:443"

# 环境变量
ENV_VARS="
APP_ENV=production
DATABASE_URL=mysql://root:pass@mysql:3306/mydb
TZ=Asia/Shanghai
"

# 卷挂载
VOLUMES="
/data/myapp:/app/data
/logs/myapp:/app/logs
"

# 主机名映射
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"

# 资源限制
CPU_LIMIT="2.0"
MEMORY_LIMIT="1g"
```

### 第二步: 创建执行脚本

执行脚本负责加载配置并构建 docker run 命令。

```bash
# 复制示例
cp example-run.sh myapp-run.sh
```

编辑执行脚本 `myapp-run.sh`:

```bash
#!/usr/bin/env bash

# 指定配置文件
CONFIG_FILE="myapp.env"

# 加载配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/$CONFIG_FILE"

# ... 其他代码保持不变 ...

# 在这里可以添加任何你需要的 docker run 参数
# 例如:

# 添加设备映射
CMD="$CMD --device /dev/video0:/dev/video0"

# 添加 sysctl 参数
CMD="$CMD --sysctl net.ipv4.ip_forward=1"

# 添加 ulimit
CMD="$CMD --ulimit nofile=65536"

# 添加 tmpfs
CMD="$CMD --tmpfs /tmp:rw,noexec,nosuid,size=1g"

# ... 继续构建命令 ...

# 执行命令
eval "$CMD"
```

### 第三步: 管理容器

使用管理脚本进行容器操作:

```bash
# 启动容器
./docker-manager.sh myapp-run.sh start

# 查看状态
./docker-manager.sh myapp-run.sh status

# 查看日志
./docker-manager.sh myapp-run.sh logs

# 实时查看日志
./docker-manager.sh myapp-run.sh logs -f

# 进入容器
./docker-manager.sh myapp-run.sh exec

# 重启容器
./docker-manager.sh myapp-run.sh restart

# 停止容器
./docker-manager.sh myapp-run.sh stop

# 删除容器
./docker-manager.sh myapp-run.sh remove

# 删除容器和镜像
./docker-manager.sh myapp-run.sh remove-all
```

---

## 💡 实际应用示例

### 示例 1: MySQL 数据库

**配置文件: `mysql.env`**

```bash
CONTAINER_NAME="mysql-db"
IMAGE_NAME="mysql:8.0"
NETWORK_NAME="backend-net"
CONTAINER_IP="172.20.0.10"  # 静态 IP

PORTS="3306:3306"

ENV_VARS="
MYSQL_ROOT_PASSWORD=YourStrongPassword123!
MYSQL_DATABASE=myapp_db
MYSQL_USER=myapp_user
MYSQL_PASSWORD=MyApp_Pass123!
TZ=Asia/Shanghai
"

NAMED_VOLUMES="
mysql-data:/var/lib/mysql
"

CPU_LIMIT="2.0"
MEMORY_LIMIT="2g"
```

**使用:**

```bash
./docker-manager.sh mysql-run.sh start
./docker-manager.sh mysql-run.sh logs -f
```

### 示例 2: Nginx 反向代理

**配置文件: `nginx.env`**

```bash
CONTAINER_NAME="nginx-proxy"
IMAGE_NAME="nginx:alpine"
NETWORK_NAME="frontend-net"
CONTAINER_IP="172.20.0.20"

PORTS="80:80 443:443"

VOLUMES="
/data/nginx/conf.d:/etc/nginx/conf.d:ro
/data/nginx/ssl:/etc/nginx/ssl:ro
/data/nginx/logs:/var/log/nginx
"

# 添加后端服务器的主机名映射
EXTRA_HOSTS="
172.20.0.10:backend-api.local
172.20.0.11:backend-cache.local
172.20.0.12:backend-db.local
"
```

**使用:**

```bash
# 创建网络
docker network create --subnet=172.20.0.0/16 frontend-net

# 启动
./docker-manager.sh nginx-run.sh start
```

### 示例 3: 需要特殊权限的应用

**配置文件: `privileged-app.env`**

```bash
CONTAINER_NAME="privileged-app"
IMAGE_NAME="my-app:latest"

# 设备映射
DEVICES="
/dev/video0:/dev/video0:rwm
/dev/snd:/dev/snd:rwm
"

# 添加 Capabilities
CAP_ADD="NET_ADMIN SYS_TIME SYS_PTRACE"

# Sysctl 参数
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6=0
"

# Ulimit 配置
ULIMIT_NOFILE="65536"
ULIMIT_NPROC="8192"
```

**执行脚本: `privileged-app-run.sh`**

在执行脚本中已经实现了对这些参数的支持,参考 `advanced-app-run.sh`。

---

## 🎯 高级用法

### 1. 使用静态 IP

```bash
# 创建自定义网络
docker network create --subnet=172.20.0.0/16 my-net

# 在配置文件中设置
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"
```

### 2. 添加主机名映射

在配置文件中:

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
10.0.0.5:external-api.com
"
```

### 3. 映射设备

在配置文件中:

```bash
DEVICES="
/dev/video0:/dev/video0:rwm
/dev/snd:/dev/snd:rwm
"
```

### 4. 配置 Sysctl 参数

在配置文件中:

```bash
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
net.core.somaxconn=65535
"
```

在执行脚本中使用:

```bash
if [ -n "$SYSCTL_PARAMS" ]; then
    while IFS= read -r param; do
        [ -z "$param" ] && continue
        CMD="$CMD --sysctl $param"
    done <<< "$SYSCTL_PARAMS"
fi
```

### 5. 自定义任何 Docker 参数

如果配置文件不支持某个参数,直接在执行脚本中添加:

```bash
# 在执行脚本中添加
CMD="$CMD --tmpfs /tmp:rw,noexec,nosuid,size=1g"
CMD="$CMD --shm-size 2g"
CMD="$CMD --pids-limit 100"
CMD="$CMD --storage-opt size=10G"
```

---

## 📋 命令参考

### docker-manager.sh 命令

```bash
./docker-manager.sh <执行脚本> <命令> [选项]
```

| 命令 | 说明 | 示例 |
|------|------|------|
| `start` | 启动容器 | `./docker-manager.sh myapp-run.sh start` |
| `stop` | 停止容器 | `./docker-manager.sh myapp-run.sh stop` |
| `restart` | 重启容器 | `./docker-manager.sh myapp-run.sh restart` |
| `remove` / `rm` | 删除容器 | `./docker-manager.sh myapp-run.sh rm` |
| `remove-all` / `rmi` | 删除容器和镜像 | `./docker-manager.sh myapp-run.sh rmi` |
| `status` / `ps` | 查看状态 | `./docker-manager.sh myapp-run.sh status` |
| `logs [lines]` | 查看日志 | `./docker-manager.sh myapp-run.sh logs 200` |
| `logs -f` | 实时日志 | `./docker-manager.sh myapp-run.sh logs -f` |
| `exec [shell]` | 进入容器 | `./docker-manager.sh myapp-run.sh exec bash` |
| `inspect` | 查看详细信息 | `./docker-manager.sh myapp-run.sh inspect` |
| `stats` | 查看资源使用 | `./docker-manager.sh myapp-run.sh stats` |
| `help` | 显示帮助 | `./docker-manager.sh help` |

---

## 🔧 配置文件参数说明

### 基本配置

```bash
CONTAINER_NAME="myapp"              # 容器名称（必需）
IMAGE_NAME="nginx:latest"           # 镜像名称（必需）
CONTAINER_HOSTNAME="myapp.local"    # 容器主机名
RESTART_POLICY="unless-stopped"     # 重启策略
```

### 网络配置

```bash
NETWORK_MODE="bridge"               # 网络模式: bridge, host, none
NETWORK_NAME="my-network"           # 自定义网络名称
CONTAINER_IP="172.20.0.100"         # 静态 IP（需要自定义网络）
```

### 端口映射

```bash
PORTS="8080:80 8443:443"            # 端口映射（空格分隔）
```

### 环境变量

```bash
ENV_VARS="
DATABASE_HOST=mysql
DATABASE_PORT=3306
APP_ENV=production
TZ=Asia/Shanghai
"
```

### 卷挂载

```bash
# 主机路径挂载
VOLUMES="
/data/myapp:/app/data
/logs/myapp:/app/logs:ro
"

# 命名卷
NAMED_VOLUMES="
myapp-data:/app/data
myapp-cache:/app/cache
"
```

### 资源限制

```bash
CPU_LIMIT="2.0"                     # CPU 核心数
CPU_SHARES="1024"                   # CPU 份额
MEMORY_LIMIT="1g"                   # 内存限制
MEMORY_RESERVATION="512m"           # 内存预留
```

### 健康检查

```bash
HEALTH_CHECK_ENABLED="true"
HEALTH_CHECK_CMD="curl -f http://localhost/ || exit 1"
HEALTH_CHECK_INTERVAL="30s"
HEALTH_CHECK_TIMEOUT="10s"
HEALTH_CHECK_RETRIES="3"
HEALTH_CHECK_START_PERIOD="60s"
```

### 主机名映射

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"
```

### DNS 配置

```bash
DNS_SERVERS="8.8.8.8 8.8.4.4"      # DNS 服务器
DNS_SEARCH="example.com local"      # DNS 搜索域
```

### 安全配置

```bash
PRIVILEGED="false"                  # 特权模式
CAP_ADD="NET_ADMIN SYS_TIME"       # 添加 Capabilities
CAP_DROP="MKNOD"                   # 删除 Capabilities
READ_ONLY="false"                  # 只读根文件系统
RUN_AS_USER="1000:1000"            # 运行用户
```

### 设备映射

```bash
DEVICES="
/dev/video0:/dev/video0:rwm
/dev/snd:/dev/snd:rwm
"
```

### 日志配置

```bash
LOG_DRIVER="json-file"              # 日志驱动
LOG_MAX_SIZE="10m"                  # 单文件最大大小
LOG_MAX_FILE="3"                    # 保留文件数量
```

---

## 🎨 最佳实践

### 1. 文件组织

推荐的目录结构:

```
project/
├── docker-manager.sh           # 管理脚本
├── example.env                 # 配置文件模板
├── example-run.sh              # 执行脚本模板
├── apps/                       # 应用配置目录
│   ├── mysql.env
│   ├── mysql-run.sh
│   ├── redis.env
│   ├── redis-run.sh
│   ├── nginx.env
│   └── nginx-run.sh
└── data/                       # 数据目录
    ├── mysql/
    ├── redis/
    └── nginx/
```

### 2. 命名规范

- 配置文件: `<应用名>.env`
- 执行脚本: `<应用名>-run.sh`
- 容器名称: `<应用名>-<环境>`

示例:
```
myapp-prod.env
myapp-prod-run.sh
CONTAINER_NAME="myapp-prod"
```

### 3. 安全建议

- 敏感信息(密码)使用环境变量或 Docker Secrets
- 生产环境设置资源限制
- 使用非 root 用户运行容器
- 启用只读根文件系统(如果可能)
- 定期更新镜像

### 4. 网络规划

```bash
# 创建不同用途的网络
docker network create --subnet=172.20.0.0/16 backend-net
docker network create --subnet=172.21.0.0/16 frontend-net
docker network create --subnet=172.22.0.0/16 data-net

# 分配 IP 段
# Backend: 172.20.0.10-50
# Frontend: 172.21.0.10-50
# Data: 172.22.0.10-50
```

### 5. 备份策略

```bash
# 备份配置文件
tar -czf configs-backup-$(date +%Y%m%d).tar.gz apps/*.env apps/*-run.sh

# 备份数据卷
docker run --rm -v mysql-data:/data -v $(pwd):/backup alpine \
    tar -czf /backup/mysql-data-$(date +%Y%m%d).tar.gz /data
```

---

## ❓ 常见问题

### Q1: 如何查看容器实时日志?

```bash
./docker-manager.sh myapp-run.sh logs -f
```

### Q2: 如何进入容器调试?

```bash
# 使用 bash
./docker-manager.sh myapp-run.sh exec

# 使用 sh (Alpine 镜像)
./docker-manager.sh myapp-run.sh exec sh
```

### Q3: 如何使用静态 IP?

```bash
# 1. 创建自定义网络
docker network create --subnet=172.20.0.0/16 my-net

# 2. 在配置文件中设置
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"

# 3. 启动容器
./docker-manager.sh myapp-run.sh start
```

### Q4: 如何添加主机名映射?

在配置文件中添加:

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"
```

### Q5: 如何使用不支持的 Docker 参数?

直接在执行脚本中添加:

```bash
# 在执行脚本的命令构建部分添加
CMD="$CMD --your-parameter value"
```

### Q6: 如何更新容器?

```bash
# 1. 拉取新镜像
docker pull new-image:tag

# 2. 更新配置文件中的镜像名
vi myapp.env

# 3. 重新创建容器
./docker-manager.sh myapp-run.sh stop
./docker-manager.sh myapp-run.sh remove
./docker-manager.sh myapp-run.sh start
```

### Q7: 如何批量管理多个容器?

```bash
# 批量启动
for app in mysql redis nginx; do
    ./docker-manager.sh ${app}-run.sh start
done

# 批量查看状态
for app in mysql redis nginx; do
    echo "=== $app ==="
    ./docker-manager.sh ${app}-run.sh status
done
```

---

## 🔄 从 V1 迁移到 V2

### 迁移步骤

1. **保留现有配置文件**

V1 的配置文件可以直接作为 V2 的配置文件使用:

```bash
# V1 配置文件
cp mysql.conf mysql.env
```

2. **创建执行脚本**

```bash
# 复制模板
cp example-run.sh mysql-run.sh

# 修改配置文件路径
vi mysql-run.sh
# CONFIG_FILE="mysql.env"
```

3. **测试新方案**

```bash
./docker-manager.sh mysql-run.sh start
```

### 对比示例

**V1 方式:**

```bash
./docker-run-template.sh -c mysql.conf start
./docker-run-template.sh -c mysql.conf logs -f
```

**V2 方式:**

```bash
./docker-manager.sh mysql-run.sh start
./docker-manager.sh mysql-run.sh logs -f
```

---

## 📚 参考资料

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Run 参考](https://docs.docker.com/engine/reference/run/)
- [Docker 网络](https://docs.docker.com/network/)
- [Docker 卷](https://docs.docker.com/storage/volumes/)

---

## 📄 许可证

本项目与 quick-deploy 使用相同的许可证。

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

---

**Happy Dockering! 🐳**

