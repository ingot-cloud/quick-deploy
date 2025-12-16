# Docker 容器部署与管理脚本

通用的 Docker 容器管理方案,采用**配置文件 + 执行脚本**分离的灵活架构。

## 🏗️ 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker 管理架构                           │
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

## ✨ 核心特性

- ✅ **完全灵活** - 支持任意 Docker run 参数
- ✅ **易于维护** - 配置和命令分离,清晰明了
- ✅ **无需适配** - Docker 更新后无需修改管理脚本
- ✅ **复用简单** - 复制配置文件和执行脚本即可

## 🎯 支持的高级参数

| 参数 | 功能 | 状态 |
|------|------|------|
| `--ip` | 静态 IP 配置 | ✅ |
| `--add-host` | 主机名映射 | ✅ |
| `--device` | 设备映射 | ✅ |
| `--cap-add` | Linux Capabilities | ✅ |
| `--sysctl` | 内核参数 | ✅ |
| `--ulimit` | 资源限制 | ✅ |
| `--dns` | DNS 配置 | ✅ |
| `--tmpfs` | 临时文件系统 | ✅ |
| 其他参数 | 直接在执行脚本中添加 | ✅ |

---

## 🚀 快速开始

### 方式 1: 使用示例快速部署

```bash
cd scripts

# 启动 MySQL
./docker-manager.sh examples/mysql-run.sh start

# 启动 Redis
./docker-manager.sh examples/redis-run.sh start

# 启动 Nginx
./docker-manager.sh examples/nginx-run.sh start

# 查看高级示例(展示所有高级参数用法)
./docker-manager.sh examples/advanced-app-run.sh start
```

### 方式 2: 创建自己的应用

```bash
# 1. 复制模板
cp example.env myapp.env
cp example-run.sh myapp-run.sh

# 2. 编辑配置文件
vi myapp.env

# 3. 编辑执行脚本(修改 CONFIG_FILE 路径)
vi myapp-run.sh

# 4. 启动容器
./docker-manager.sh myapp-run.sh start
```

---

## 📚 文档

- **快速开始**: [QUICK_START.md](QUICK_START.md) - 5 分钟上手
- **详细指南**: [DOCKER_MANAGER_V2_GUIDE.md](DOCKER_MANAGER_V2_GUIDE.md) - 完整使用文档
- **配置模板**: [example.env](example.env) - 配置文件模板(包含所有可用参数)
- **执行模板**: [example-run.sh](example-run.sh) - 执行脚本模板
- **应用示例**: [examples/README.md](examples/README.md) - MySQL, Redis, Nginx 等实际示例

---

## 💡 高级用法示例

### 示例 1: 使用静态 IP

```bash
# 1. 创建自定义网络
docker network create --subnet=172.20.0.0/16 my-net

# 2. 在配置文件中设置
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"

# 3. 启动容器
./docker-manager.sh myapp-run.sh start
```

### 示例 2: 添加主机名映射

在配置文件中添加:

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
192.168.1.12:api.local
"
```

### 示例 3: 映射设备

在配置文件中添加:

```bash
DEVICES="
/dev/video0:/dev/video0:rwm
/dev/nvidia0:/dev/nvidia0:rwm
"
```

### 示例 4: 配置内核参数

在配置文件中添加:

```bash
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
net.core.somaxconn=65535
"
```

### 示例 5: 自定义任意参数

直接在执行脚本中添加:

```bash
# 在执行脚本中添加任意参数
CMD="$CMD --tmpfs /tmp:rw,size=1g"
CMD="$CMD --shm-size 2g"
CMD="$CMD --pids-limit 100"
CMD="$CMD --storage-opt size=10G"
```

---

## 📋 常用命令

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

## 📂 目录结构

```
scripts/
├── docker-manager.sh            # 管理脚本 ⭐
├── example.env                  # 配置文件模板 ⭐
├── example-run.sh               # 执行脚本模板 ⭐
├── DOCKER_MANAGER_V2_GUIDE.md   # 详细文档
├── QUICK_START.md               # 快速开始
├── README.md                    # 本文件
└── examples/                 # 应用示例 ⭐
    ├── README.md
    ├── mysql.env
    ├── mysql-run.sh
    ├── redis.env
    ├── redis-run.sh
    ├── nginx.env
    ├── nginx-run.sh
    ├── advanced-app.env         # 高级示例
    └── advanced-app-run.sh
```

---

## 🎨 最佳实践

### 1. 文件组织

推荐的目录结构:

```
project/
├── docker-manager.sh           # 管理脚本
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

- 敏感信息使用环境变量或 Docker Secrets
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

---

## ❓ 常见问题

### Q1: 如何使用静态 IP?

```bash
# 1. 创建自定义网络
docker network create --subnet=172.20.0.0/16 my-net

# 2. 在配置文件中设置
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"

# 3. 启动容器
./docker-manager.sh myapp-run.sh start
```

### Q2: 如何添加主机名映射?

在配置文件中添加:

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"
```

### Q3: 如何使用不支持的 Docker 参数?

直接在执行脚本中添加:

```bash
CMD="$CMD --your-parameter value"
```

### Q4: 如何批量管理多个容器?

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

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

---

## 📄 许可证

与主项目保持一致。

---

**开始使用吧! 🚀**
