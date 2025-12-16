#!/usr/bin/env bash

###############################################################################
# 高级应用容器运行脚本
# 展示如何使用 --ip, --add-host, --device, --cap-add, --sysctl 等参数
###############################################################################

CONFIG_FILE="advanced-app.env"

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

# 创建自定义网络（如果不存在）
if [ -n "$NETWORK_NAME" ]; then
    if ! docker network inspect "$NETWORK_NAME" &> /dev/null; then
        echo "创建自定义网络: $NETWORK_NAME"
        docker network create --subnet=172.20.0.0/16 "$NETWORK_NAME"
    fi
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

# ========== 网络配置（包含静态 IP）==========
if [ -n "$NETWORK_NAME" ]; then
    CMD="$CMD --network $NETWORK_NAME"
    
    # 静态 IP 配置（这是原模板不支持的功能！）
    if [ -n "$CONTAINER_IP" ]; then
        CMD="$CMD --ip $CONTAINER_IP"
        echo "使用静态 IP: $CONTAINER_IP"
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
[ -n "$CPU_SHARES" ] && CMD="$CMD --cpu-shares $CPU_SHARES"
[ -n "$MEMORY_LIMIT" ] && CMD="$CMD --memory $MEMORY_LIMIT"
[ -n "$MEMORY_RESERVATION" ] && CMD="$CMD --memory-reservation $MEMORY_RESERVATION"

# 健康检查
if [ "$HEALTH_CHECK_ENABLED" = "true" ] && [ -n "$HEALTH_CHECK_CMD" ]; then
    CMD="$CMD --health-cmd=\"$HEALTH_CHECK_CMD\""
    CMD="$CMD --health-interval=${HEALTH_CHECK_INTERVAL}"
    CMD="$CMD --health-timeout=${HEALTH_CHECK_TIMEOUT}"
    CMD="$CMD --health-retries=${HEALTH_CHECK_RETRIES}"
    [ -n "$HEALTH_CHECK_START_PERIOD" ] && CMD="$CMD --health-start-period=${HEALTH_CHECK_START_PERIOD}"
fi

# 日志配置
CMD="$CMD --log-driver ${LOG_DRIVER}"
if [ "$LOG_DRIVER" = "json-file" ]; then
    CMD="$CMD --log-opt max-size=${LOG_MAX_SIZE}"
    CMD="$CMD --log-opt max-file=${LOG_MAX_FILE}"
fi

# ========== 主机名映射（这是原模板不支持的功能！）==========
if [ -n "$EXTRA_HOSTS" ]; then
    while IFS= read -r host; do
        [ -z "$host" ] && continue
        CMD="$CMD --add-host $host"
        echo "添加主机映射: $host"
    done <<< "$EXTRA_HOSTS"
fi

# ========== DNS 配置 ==========
if [ -n "$DNS_SERVERS" ]; then
    for dns in $DNS_SERVERS; do
        CMD="$CMD --dns $dns"
    done
fi

if [ -n "$DNS_SEARCH" ]; then
    for domain in $DNS_SEARCH; do
        CMD="$CMD --dns-search $domain"
    done
fi

# ========== 安全配置 ==========
[ "$PRIVILEGED" = "true" ] && CMD="$CMD --privileged"

# Linux Capabilities 添加
if [ -n "$CAP_ADD" ]; then
    for cap in $CAP_ADD; do
        CMD="$CMD --cap-add $cap"
        echo "添加 Capability: $cap"
    done
fi

# Linux Capabilities 删除
if [ -n "$CAP_DROP" ]; then
    for cap in $CAP_DROP; do
        CMD="$CMD --cap-drop $cap"
        echo "删除 Capability: $cap"
    done
fi

[ "$READ_ONLY" = "true" ] && CMD="$CMD --read-only"
[ -n "$SECURITY_OPT" ] && CMD="$CMD --security-opt $SECURITY_OPT"

# ========== 设备映射（这是原模板不支持的功能!）==========
if [ -n "$DEVICES" ]; then
    while IFS= read -r device; do
        [ -z "$device" ] && continue
        CMD="$CMD --device $device"
        echo "映射设备: $device"
    done <<< "$DEVICES"
fi

# ========== 系统调用参数（这是原模板不支持的功能！）==========
if [ -n "$SYSCTL_PARAMS" ]; then
    while IFS= read -r param; do
        [ -z "$param" ] && continue
        CMD="$CMD --sysctl $param"
        echo "设置 sysctl: $param"
    done <<< "$SYSCTL_PARAMS"
fi

# ========== Ulimit 配置（这是原模板不支持的功能！）==========
if [ -n "$ULIMIT_NOFILE" ]; then
    CMD="$CMD --ulimit nofile=$ULIMIT_NOFILE"
    echo "设置文件描述符限制: $ULIMIT_NOFILE"
fi

if [ -n "$ULIMIT_NPROC" ]; then
    CMD="$CMD --ulimit nproc=$ULIMIT_NPROC"
    echo "设置进程数限制: $ULIMIT_NPROC"
fi

# 标签
if [ -n "$LABELS" ]; then
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        CMD="$CMD --label $label"
    done <<< "$LABELS"
fi

# 命名空间配置
[ -n "$PID_MODE" ] && CMD="$CMD --pid $PID_MODE"
[ -n "$IPC_MODE" ] && CMD="$CMD --ipc $IPC_MODE"
[ -n "$UTS_MODE" ] && CMD="$CMD --uts $UTS_MODE"

# 镜像
CMD="$CMD $IMAGE_NAME"

# 启动命令
if [ -n "$CONTAINER_CMD" ]; then
    CMD="$CMD $CONTAINER_CMD"
fi

# 执行命令
echo ""
echo "执行命令:"
echo "$CMD"
echo ""

eval "$CMD"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 容器创建成功!"
    echo ""
    echo "容器信息:"
    echo "  名称: $CONTAINER_NAME"
    echo "  镜像: $IMAGE_NAME"
    [ -n "$CONTAINER_IP" ] && echo "  IP: $CONTAINER_IP"
    echo ""
    echo "高级特性已启用:"
    [ -n "$CONTAINER_IP" ] && echo "  ✓ 静态 IP: $CONTAINER_IP"
    [ -n "$EXTRA_HOSTS" ] && echo "  ✓ 主机名映射: $(echo "$EXTRA_HOSTS" | wc -l | tr -d ' ') 条"
    [ -n "$DEVICES" ] && echo "  ✓ 设备映射: $(echo "$DEVICES" | grep -v '^$' | wc -l | tr -d ' ') 个"
    [ -n "$CAP_ADD" ] && echo "  ✓ Capabilities: $CAP_ADD"
    [ -n "$SYSCTL_PARAMS" ] && echo "  ✓ Sysctl 参数: $(echo "$SYSCTL_PARAMS" | grep -v '^$' | wc -l | tr -d ' ') 个"
    echo ""
    exit 0
else
    echo ""
    echo "✗ 容器创建失败!"
    exit 1
fi

