# Docker 管理脚本 V2 - 应用示例

这个目录包含了使用新架构的实际应用示例。

## 📁 示例列表

### 1. MySQL 数据库

- **配置文件**: `mysql.env`
- **执行脚本**: `mysql-run.sh`
- **说明**: MySQL 8.0 数据库,包含数据持久化、健康检查、资源限制配置

```bash
# 使用方法
cd scripts
./docker-manager.sh examples-v2/mysql-run.sh start
./docker-manager.sh examples-v2/mysql-run.sh logs -f
```

### 2. Redis 缓存

- **配置文件**: `redis.env`
- **执行脚本**: `redis-run.sh`
- **说明**: Redis 7 缓存服务器,支持数据持久化和自定义配置

```bash
# 使用方法
cd scripts
./docker-manager.sh examples-v2/redis-run.sh start
./docker-manager.sh examples-v2/redis-run.sh status
```

### 3. Nginx Web 服务器

- **配置文件**: `nginx.env`
- **执行脚本**: `nginx-run.sh`
- **说明**: Nginx Web 服务器,展示如何使用 `--add-host` 进行主机名映射(用于反向代理)

```bash
# 使用方法
cd scripts
./docker-manager.sh examples-v2/nginx-run.sh start
./docker-manager.sh examples-v2/nginx-run.sh exec
```

### 4. 高级应用示例 ⭐

- **配置文件**: `advanced-app.env`
- **执行脚本**: `advanced-app-run.sh`
- **说明**: 展示如何使用高级参数:
  - ✅ `--ip` - 静态 IP 配置
  - ✅ `--add-host` - 主机名映射
  - ✅ `--device` - 设备映射
  - ✅ `--cap-add` - Linux Capabilities
  - ✅ `--sysctl` - 内核参数
  - ✅ `--ulimit` - 资源限制
  - ✅ `--dns` - DNS 配置

```bash
# 使用方法(需要先创建网络)
docker network create --subnet=172.20.0.0/16 custom-net
cd scripts
./docker-manager.sh examples-v2/advanced-app-run.sh start
```

## 🚀 快速开始

### 直接使用示例

```bash
# 1. 进入 scripts 目录
cd scripts

# 2. 选择一个示例启动
./docker-manager.sh examples-v2/mysql-run.sh start
```

### 基于示例创建自己的应用

```bash
# 1. 复制示例文件
cp examples-v2/mysql.env myapp.env
cp examples-v2/mysql-run.sh myapp-run.sh

# 2. 编辑配置文件
vi myapp.env

# 3. 编辑执行脚本(修改 CONFIG_FILE 路径)
vi myapp-run.sh
# CONFIG_FILE="myapp.env"

# 4. 启动容器
./docker-manager.sh myapp-run.sh start
```

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

## 🌟 高级用法示例

### 使用静态 IP

```bash
# 1. 创建自定义网络
docker network create --subnet=172.20.0.0/16 backend-net

# 2. 修改配置文件
NETWORK_NAME="backend-net"
CONTAINER_IP="172.20.0.10"

# 3. 启动容器
./docker-manager.sh myapp-run.sh start
```

### 添加主机名映射

在配置文件中添加:

```bash
EXTRA_HOSTS="
192.168.1.100:database.local
192.168.1.101:cache.local
192.168.1.102:api.local
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

在执行脚本中已实现支持,参考 `advanced-app-run.sh`。

### 配置内核参数

在配置文件中添加:

```bash
SYSCTL_PARAMS="
net.ipv4.ip_forward=1
net.core.somaxconn=65535
"
```

## 🔧 故障排查

### 容器无法启动

```bash
# 查看详细错误
./docker-manager.sh myapp-run.sh logs

# 检查镜像
docker images | grep myapp

# 手动测试命令
# 从执行脚本输出的命令复制,手动执行
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

## 📚 更多信息

- 查看主文档: [DOCKER_MANAGER_V2_GUIDE.md](../DOCKER_MANAGER_V2_GUIDE.md)
- 查看模板文件: [example.env](../example.env) 和 [example-run.sh](../example-run.sh)

## 💡 提示

1. **修改配置前先备份**
   ```bash
   cp mysql.env mysql.env.bak
   ```

2. **测试配置**
   ```bash
   # 启动后检查状态
   ./docker-manager.sh mysql-run.sh status
   ./docker-manager.sh mysql-run.sh logs
   ```

3. **使用版本控制**
   ```bash
   git add mysql.env mysql-run.sh
   git commit -m "Add MySQL configuration"
   ```

4. **环境分离**
   ```bash
   # 为不同环境创建不同配置
   mysql-dev.env / mysql-dev-run.sh
   mysql-prod.env / mysql-prod-run.sh
   ```

---

**祝使用愉快! 🚀**

