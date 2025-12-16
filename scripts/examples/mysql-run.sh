#!/usr/bin/env bash

###############################################################################
# MySQL 容器运行脚本
###############################################################################

CONFIG_FILE="mysql.env"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
if [ -f "$SCRIPT_DIR/$CONFIG_FILE" ]; then
    source "$SCRIPT_DIR/$CONFIG_FILE"
else
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 检查必需变量
if [ -z "$CONTAINER_NAME" ] || [ -z "$IMAGE_NAME" ]; then
    echo "错误: 缺少必需的配置项"
    exit 1
fi

# 创建必要的目录
if [ -n "$VOLUMES" ]; then
    while IFS= read -r volume; do
        [ -z "$volume" ] && continue
        host_path=$(echo "$volume" | cut -d':' -f1)
        if [[ "$host_path" == /* ]] && [ ! -e "$host_path" ]; then
            echo "创建目录: $host_path"
            mkdir -p "$host_path"
        fi
    done <<< "$VOLUMES"
fi

# 检查镜像
echo "检查镜像: $IMAGE_NAME"
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "镜像不存在，尝试拉取..."
    docker pull "$IMAGE_NAME"
fi

echo "开始启动容器: $CONTAINER_NAME"

# 构建 docker run 命令
CMD="docker run -d"
CMD="$CMD --name $CONTAINER_NAME"
CMD="$CMD --hostname ${CONTAINER_HOSTNAME}"
CMD="$CMD --restart ${RESTART_POLICY}"

# 网络配置
if [ -n "$NETWORK_NAME" ]; then
    CMD="$CMD --network $NETWORK_NAME"
    if [ -n "$CONTAINER_IP" ]; then
        CMD="$CMD --ip $CONTAINER_IP"
    fi
elif [ -n "$NETWORK_MODE" ]; then
    CMD="$CMD --network $NETWORK_MODE"
fi

# 端口映射
for port in $PORTS; do
    CMD="$CMD -p $port"
done

# 环境变量
while IFS= read -r env_var; do
    [ -z "$env_var" ] && continue
    CMD="$CMD -e \"$env_var\""
done <<< "$ENV_VARS"

# 卷挂载
if [ -n "$VOLUMES" ]; then
    while IFS= read -r volume; do
        [ -z "$volume" ] && continue
        CMD="$CMD -v $volume"
    done <<< "$VOLUMES"
fi

if [ -n "$NAMED_VOLUMES" ]; then
    while IFS= read -r volume; do
        [ -z "$volume" ] && continue
        CMD="$CMD -v $volume"
    done <<< "$NAMED_VOLUMES"
fi

# 时区文件
if [ "$MOUNT_TIMEZONE" = "true" ]; then
    CMD="$CMD -v /etc/localtime:/etc/localtime:ro"
    CMD="$CMD -v /etc/timezone:/etc/timezone:ro"
fi

# 资源限制
[ -n "$CPU_LIMIT" ] && CMD="$CMD --cpus $CPU_LIMIT"
[ -n "$MEMORY_LIMIT" ] && CMD="$CMD --memory $MEMORY_LIMIT"

# 健康检查
if [ "$HEALTH_CHECK_ENABLED" = "true" ] && [ -n "$HEALTH_CHECK_CMD" ]; then
    CMD="$CMD --health-cmd=\"$HEALTH_CHECK_CMD\""
    CMD="$CMD --health-interval=${HEALTH_CHECK_INTERVAL}"
    CMD="$CMD --health-timeout=${HEALTH_CHECK_TIMEOUT}"
    CMD="$CMD --health-retries=${HEALTH_CHECK_RETRIES}"
    CMD="$CMD --health-start-period=${HEALTH_CHECK_START_PERIOD}"
fi

# 日志配置
CMD="$CMD --log-driver ${LOG_DRIVER}"
if [ "$LOG_DRIVER" = "json-file" ]; then
    CMD="$CMD --log-opt max-size=${LOG_MAX_SIZE}"
    CMD="$CMD --log-opt max-file=${LOG_MAX_FILE}"
fi

# 主机名映射
if [ -n "$EXTRA_HOSTS" ]; then
    while IFS= read -r host; do
        [ -z "$host" ] && continue
        CMD="$CMD --add-host $host"
    done <<< "$EXTRA_HOSTS"
fi

# 标签
if [ -n "$LABELS" ]; then
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        CMD="$CMD --label $label"
    done <<< "$LABELS"
fi

# 镜像
CMD="$CMD $IMAGE_NAME"

# 执行命令
echo ""
echo "执行命令:"
echo "$CMD"
echo ""

eval "$CMD"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ MySQL 容器创建成功!"
    echo ""
    echo "连接信息:"
    echo "  主机: localhost"
    echo "  端口: 3306"
    echo "  数据库: myapp_db"
    echo "  用户: myapp_user"
    echo "  密码: 见配置文件"
    echo ""
    exit 0
else
    echo ""
    echo "✗ MySQL 容器创建失败!"
    exit 1
fi

