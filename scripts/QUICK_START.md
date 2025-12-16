# Docker 管理脚本 - 快速开始 🚀

## ⚡ 3 分钟上手

### 1️⃣ 使用现成示例 (最快)

```bash
cd /path/to/quick-deploy/scripts

# 只需一个命令,启动 MySQL
./docker-manager.sh examples/mysql.env start

# 只需一个命令,启动 Redis
./docker-manager.sh examples/redis.env start

# 只需一个命令,启动 Nginx
./docker-manager.sh examples/nginx.env start

# 查看状态
./docker-manager.sh examples/mysql.env status
```

### 2️⃣ 创建自己的应用

```bash
# 1. 复制配置文件模板
cp example.env myapp.env

# 2. 编辑配置(只需修改这一个文件!)
vi myapp.env
# 至少修改: CONTAINER_NAME, IMAGE_NAME

# 3. 启动(无需创建执行脚本!)
./docker-manager.sh myapp.env start
```

就这么简单!✨

---

## 🎯 核心改进

**现在你只需要一个 `.env` 配置文件!**

### 之前的方式:
```bash
# 需要两个文件
cp example.env myapp.env
cp example-run.sh myapp-run.sh
vi myapp.env
vi myapp-run.sh  # 还要修改 CONFIG_FILE
./docker-manager.sh myapp-run.sh start
```

### 现在的方式:
```bash
# 只需一个文件! ⭐
cp example.env myapp.env
vi myapp.env
./docker-manager.sh myapp.env start
```

---

## 💡 高级用法

### 使用静态 IP

```bash
# 1. 创建网络
docker network create --subnet=172.20.0.0/16 my-net

# 2. 在配置文件中添加
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"

# 3. 启动
./docker-manager.sh myapp.env start
```

### 添加主机名映射

```bash
# 在配置文件中添加
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
"

# 启动后容器内可以访问这些主机名
./docker-manager.sh myapp.env start
```

### 自定义执行脚本(高级)

如果需要特殊逻辑,可以创建自定义执行脚本:

```bash
# 1. 复制通用脚本
cp docker-run.sh myapp-custom-run.sh

# 2. 修改 CONFIG_FILE
vi myapp-custom-run.sh
# CONFIG_FILE="myapp.env"

# 3. 添加自定义逻辑
# ... 在脚本中添加特殊处理 ...

# 4. 使用自定义脚本
./docker-manager.sh myapp-custom-run.sh start
```

---

## 📋 常用命令

```bash
# 管理命令
./docker-manager.sh myapp.env start      # 启动
./docker-manager.sh myapp.env stop       # 停止
./docker-manager.sh myapp.env restart    # 重启
./docker-manager.sh myapp.env remove     # 删除
./docker-manager.sh myapp.env status     # 状态

# 调试命令
./docker-manager.sh myapp.env logs       # 查看日志
./docker-manager.sh myapp.env logs -f    # 实时日志
./docker-manager.sh myapp.env exec       # 进入容器
./docker-manager.sh myapp.env inspect    # 详细信息
./docker-manager.sh myapp.env stats      # 资源使用
```

---

## 📝 配置文件最小示例

创建 `myapp.env`:

```bash
# 最简配置
CONTAINER_NAME="myapp"
IMAGE_NAME="nginx:alpine"
PORTS="8080:80"
```

就这些!其他都有默认值。

---

## 🌟 完整配置示例

```bash
# 基本配置
CONTAINER_NAME="myapp"
IMAGE_NAME="nginx:alpine"
RESTART_POLICY="unless-stopped"

# 网络配置(支持静态 IP)
NETWORK_NAME="my-net"
CONTAINER_IP="172.20.0.100"

# 端口映射
PORTS="8080:80 8443:443"

# 环境变量
ENV_VARS="
APP_ENV=production
TZ=Asia/Shanghai
"

# 卷挂载
VOLUMES="
/data/myapp:/app/data
"

# 主机名映射
EXTRA_HOSTS="
192.168.1.10:database.local
"

# 资源限制
CPU_LIMIT="2.0"
MEMORY_LIMIT="1g"
```

---

## 🎓 学习路径

1. **快速体验** (现在) - 使用示例快速启动
2. **了解配置** - 查看 [example.env](example.env) 了解所有配置项
3. **深入学习** - 阅读 [DOCKER_MANAGER_V2_GUIDE.md](DOCKER_MANAGER_V2_GUIDE.md)
4. **实际应用** - 创建自己的应用配置

---

## 💡 为什么这么简单?

因为我们把公共逻辑提取到了通用的 `docker-run.sh` 脚本中:

- ✅ 支持所有 Docker 参数(--ip, --add-host, --device 等)
- ✅ 无需为每个应用创建执行脚本
- ✅ 只需编辑配置文件即可
- ✅ 如需自定义逻辑,仍可创建自定义脚本

---

**就是这么简单! 🎉**

开始使用: `./docker-manager.sh examples/mysql.env start`
