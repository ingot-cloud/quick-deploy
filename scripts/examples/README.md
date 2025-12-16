# Docker 管理脚本 - 应用示例

这个目录包含了各种应用的配置文件示例。

## 📁 示例列表

### 1. MySQL 数据库 ⭐

- **配置文件**: `mysql.env`
- **说明**: MySQL 8.0 数据库,包含数据持久化、健康检查、资源限制配置

```bash
# 使用方法(只需配置文件即可)
cd scripts
./docker-manager.sh examples/mysql.env start
./docker-manager.sh examples/mysql.env logs -f
./docker-manager.sh examples/mysql.env status
```

### 2. Redis 缓存 ⭐

- **配置文件**: `redis.env`
- **说明**: Redis 7 缓存服务器,支持数据持久化和自定义配置

```bash
# 使用方法
cd scripts
./docker-manager.sh examples/redis.env start
./docker-manager.sh examples/redis.env exec
```

### 3. Nginx Web 服务器 ⭐

- **配置文件**: `nginx.env`
- **说明**: Nginx Web 服务器,展示如何使用 `--add-host` 进行主机名映射(用于反向代理)

```bash
# 使用方法
cd scripts
./docker-manager.sh examples/nginx.env start
./docker-manager.sh examples/nginx.env status
```

### 4. 高级应用示例 - 自定义执行脚本 🔧

- **配置文件**: `advanced-app.env`
- **执行脚本**: `advanced-app-run.sh` (自定义脚本示例)
- **说明**: 展示如何使用自定义执行脚本实现特殊逻辑

```bash
# 使用方法(使用自定义执行脚本)
docker network create --subnet=172.20.0.0/16 custom-net
cd scripts
./docker-manager.sh examples/advanced-app-run.sh start
```

---

## 🚀 快速开始

### 方式 1: 直接使用示例 (最简单)

```bash
cd scripts

# 启动 MySQL
./docker-manager.sh examples/mysql.env start

# 启动 Redis  
./docker-manager.sh examples/redis.env start

# 启动 Nginx
./docker-manager.sh examples/nginx.env start
```

### 方式 2: 基于示例创建自己的应用

```bash
# 1. 复制示例配置文件
cp examples/mysql.env myapp.env

# 2. 编辑配置
vi myapp.env

# 3. 启动(自动使用通用执行脚本)
./docker-manager.sh myapp.env start
```

---

## 💡 架构说明

### 新的简化架构

现在你**只需要一个配置文件**就可以启动容器!

```
┌──────────────┐
│ mysql.env    │ ─────┐
│ (配置文件)   │      │
└──────────────┘      │
                      ├───> docker-manager.sh ───> docker-run.sh ───> Docker 容器
┌──────────────┐      │     (管理脚本)            (通用执行脚本)
│ redis.env    │ ─────┘
│ (配置文件)   │
└──────────────┘
```

**工作流程**:
1. 你只需编辑 `.env` 配置文件
2. 运行 `./docker-manager.sh myapp.env start`
3. 管理脚本自动使用通用的 `docker-run.sh` 执行脚本
4. 容器启动成功!

### 自定义执行脚本(高级)

如果你需要特殊的逻辑,可以创建自定义执行脚本:

```bash
# 1. 复制通用执行脚本
cp docker-run.sh myapp-custom-run.sh

# 2. 修改 CONFIG_FILE 指向你的配置
vi myapp-custom-run.sh
# CONFIG_FILE="myapp.env"

# 3. 添加自定义逻辑
# ... 在脚本中添加你需要的特殊处理 ...

# 4. 使用自定义脚本启动
./docker-manager.sh myapp-custom-run.sh start
```

---

## 📋 配置修改指南

### MySQL 配置修改

编辑 `mysql.env`:

```bash
# 修改密码
MYSQL_ROOT_PASSWORD=YourNewPassword

# 修改数据库名
MYSQL_DATABASE=your_db_name

# 修改端口
PORTS="3307:3306"  # 主机端口改为 3307

# 修改资源限制
CPU_LIMIT="4.0"
MEMORY_LIMIT="4g"

# 使用静态 IP
NETWORK_NAME="backend-net"
CONTAINER_IP="172.20.0.10"
```

### Redis 配置修改

编辑 `redis.env`:

```bash
# 使用配置文件启动
VOLUMES="
/path/to/your/redis.conf:/usr/local/etc/redis/redis.conf:ro
"
CONTAINER_CMD="redis-server /usr/local/etc/redis/redis.conf"

# 或直接用参数启动
CONTAINER_CMD="redis-server --appendonly yes --requirepass yourpassword"
```

### Nginx 配置修改

编辑 `nginx.env`:

```bash
# 修改配置文件路径
VOLUMES="
/your/nginx/html:/usr/share/nginx/html:ro
/your/nginx/conf:/etc/nginx/conf.d:ro
"

# 添加后端服务主机映射
EXTRA_HOSTS="
172.20.0.10:backend-api.local
172.20.0.11:backend-db.local
"
```

---

## 🌟 高级用法示例

### 使用静态 IP

```bash
# 1. 创建自定义网络
docker network create --subnet=172.20.0.0/16 backend-net

# 2. 在配置文件中添加
NETWORK_NAME="backend-net"
CONTAINER_IP="172.20.0.10"

# 3. 启动容器
./docker-manager.sh myapp.env start
```

### 添加主机名映射

在配置文件中添加:

```bash
EXTRA_HOSTS="
192.168.1.10:database.local
192.168.1.11:cache.local
192.168.1.12:api.local
"
```

### 映射设备(如 GPU、摄像头)

在配置文件中添加:

```bash
DEVICES="
/dev/video0:/dev/video0:rwm
/dev/nvidia0:/dev/nvidia0:rwm
"
```

### 配置内核参数

在配置文件中添加:

```bash
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
net.core.somaxconn=65535
"
```

---

## 🔧 故障排查

### 容器无法启动

```bash
# 查看详细错误
./docker-manager.sh myapp.env logs

# 检查镜像
docker images | grep myapp

# 检查配置文件语法
source myapp.env && echo "配置文件语法正确"
```

### 网络连接问题

```bash
# 检查网络
docker network ls
docker network inspect backend-net

# 检查容器 IP
docker inspect myapp | grep IPAddress

# 测试连通性
docker exec myapp ping backend-api.local
```

### 权限问题

```bash
# 检查目录权限
ls -la /data/myapp

# 修改所有者
sudo chown -R 1000:1000 /data/myapp

# 或在配置中指定用户
RUN_AS_USER="1000:1000"
```

---

## 📚 更多信息

- **快速开始**: [../QUICK_START.md](../QUICK_START.md)
- **详细文档**: [../DOCKER_MANAGER_V2_GUIDE.md](../DOCKER_MANAGER_V2_GUIDE.md)
- **配置模板**: [../example.env](../example.env)

---

## 💡 提示

1. **现在更简单了!**
   ```bash
   # 只需要配置文件,无需执行脚本
   cp examples/mysql.env myapp.env
   vi myapp.env
   ./docker-manager.sh myapp.env start
   ```

2. **测试配置**
   ```bash
   # 启动后检查状态
   ./docker-manager.sh myapp.env status
   ./docker-manager.sh myapp.env logs
   ```

3. **使用版本控制**
   ```bash
   git add myapp.env
   git commit -m "Add myapp configuration"
   ```

4. **环境分离**
   ```bash
   # 为不同环境创建不同配置
   mysql-dev.env
   mysql-prod.env
   ```

---

**祝使用愉快! 🚀**
