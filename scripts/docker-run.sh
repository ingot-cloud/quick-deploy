#!/usr/bin/env bash

###############################################################################
# Docker 容器通用运行脚本
# 
# 说明:
#   这是一个通用的执行脚本,通过环境变量 CONFIG_FILE 指定配置文件
#   通常由 docker-manager.sh 自动调用,无需手动执行
#
# 环境变量:
#   CONFIG_FILE - 配置文件路径(必需)
###############################################################################

# 检查配置文件参数
if [ -z "$CONFIG_FILE" ]; then
    echo "错误: 未设置 CONFIG_FILE 环境变量"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
elif [ -f "$SCRIPT_DIR/$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/$CONFIG_FILE"
else
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

###############################################################################
# 辅助函数
###############################################################################

# 检查必需的变量
check_required_vars() {
    local errors=0
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo "错误: 未定义 CONTAINER_NAME"
        errors=$((errors + 1))
    fi
    
    if [ -z "$IMAGE_NAME" ]; then
        echo "错误: 未定义 IMAGE_NAME"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        exit 1
    fi
}

# 创建必要的目录
create_directories() {
    if [ -n "$VOLUMES" ]; then
        while IFS= read -r volume; do
            [ -z "$volume" ] && continue
            
            # 提取主机路径
            local host_path
            host_path=$(echo "$volume" | cut -d':' -f1)
            
            # 如果是绝对路径且不存在,则创建
            if [[ "$host_path" == /* ]] && [ ! -e "$host_path" ]; then
                echo "创建目录: $host_path"
                mkdir -p "$host_path"
            fi
        done <<< "$VOLUMES"
    fi
}

# 检查镜像
check_image() {
    echo "检查镜像: $IMAGE_NAME"
    
    if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
        echo "镜像不存在,尝试拉取..."
        if docker pull "$IMAGE_NAME"; then
            echo "镜像拉取成功"
        else
            echo "错误: 镜像拉取失败"
            exit 1
        fi
    else
        echo "镜像已存在"
    fi
}

###############################################################################
# 构建 docker run 命令
###############################################################################

# 验证配置
check_required_vars

# 创建必要的目录
create_directories

# 检查镜像
check_image

echo "开始启动容器: $CONTAINER_NAME"

# 基础命令
CMD="docker run -d"

# 容器名称
CMD="$CMD --name $CONTAINER_NAME"

# 主机名
if [ -n "$CONTAINER_HOSTNAME" ]; then
    CMD="$CMD --hostname $CONTAINER_HOSTNAME"
fi

# 重启策略
CMD="$CMD --restart ${RESTART_POLICY:-unless-stopped}"

# ========== 网络配置 ==========
if [ -n "$NETWORK_NAME" ]; then
    CMD="$CMD --network $NETWORK_NAME"
    
    # 静态 IP
    if [ -n "$CONTAINER_IP" ]; then
        CMD="$CMD --ip $CONTAINER_IP"
    fi
elif [ -n "$NETWORK_MODE" ]; then
    CMD="$CMD --network $NETWORK_MODE"
fi

# ========== 端口映射 ==========
if [ -n "$PORTS" ]; then
    for port in $PORTS; do
        CMD="$CMD -p $port"
    done
fi

# ========== 环境变量 ==========
if [ -n "$ENV_VARS" ]; then
    while IFS= read -r env_var; do
        [ -z "$env_var" ] && continue
        CMD="$CMD -e \"$env_var\""
    done <<< "$ENV_VARS"
fi

# ========== 卷挂载 ==========
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

# Docker socket
if [ "$MOUNT_DOCKER_SOCKET" = "true" ]; then
    CMD="$CMD -v /var/run/docker.sock:/var/run/docker.sock"
fi

# 时区文件
if [ "$MOUNT_TIMEZONE" = "true" ]; then
    CMD="$CMD -v /etc/localtime:/etc/localtime:ro"
    CMD="$CMD -v /etc/timezone:/etc/timezone:ro"
fi

# ========== 资源限制 ==========
if [ -n "$CPU_LIMIT" ]; then
    CMD="$CMD --cpus $CPU_LIMIT"
fi

if [ -n "$CPU_SHARES" ]; then
    CMD="$CMD --cpu-shares $CPU_SHARES"
fi

if [ -n "$MEMORY_LIMIT" ]; then
    CMD="$CMD --memory $MEMORY_LIMIT"
fi

if [ -n "$MEMORY_RESERVATION" ]; then
    CMD="$CMD --memory-reservation $MEMORY_RESERVATION"
fi

# ========== 健康检查 ==========
if [ "$HEALTH_CHECK_ENABLED" = "true" ] && [ -n "$HEALTH_CHECK_CMD" ]; then
    CMD="$CMD --health-cmd=\"$HEALTH_CHECK_CMD\""
    CMD="$CMD --health-interval=${HEALTH_CHECK_INTERVAL:-30s}"
    CMD="$CMD --health-timeout=${HEALTH_CHECK_TIMEOUT:-10s}"
    CMD="$CMD --health-retries=${HEALTH_CHECK_RETRIES:-3}"
    
    if [ -n "$HEALTH_CHECK_START_PERIOD" ]; then
        CMD="$CMD --health-start-period=$HEALTH_CHECK_START_PERIOD"
    fi
fi

# ========== 用户配置 ==========
if [ -n "$RUN_AS_USER" ]; then
    CMD="$CMD --user $RUN_AS_USER"
fi

# ========== 工作目录 ==========
if [ -n "$WORKDIR" ]; then
    CMD="$CMD --workdir $WORKDIR"
fi

# ========== 日志配置 ==========
CMD="$CMD --log-driver ${LOG_DRIVER:-json-file}"
if [ "$LOG_DRIVER" = "json-file" ] || [ -z "$LOG_DRIVER" ]; then
    CMD="$CMD --log-opt max-size=${LOG_MAX_SIZE:-10m}"
    CMD="$CMD --log-opt max-file=${LOG_MAX_FILE:-3}"
fi

# ========== 主机名映射 ==========
if [ -n "$EXTRA_HOSTS" ]; then
    while IFS= read -r host; do
        [ -z "$host" ] && continue
        CMD="$CMD --add-host $host"
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
if [ "$PRIVILEGED" = "true" ]; then
    CMD="$CMD --privileged"
fi

if [ -n "$CAP_ADD" ]; then
    for cap in $CAP_ADD; do
        CMD="$CMD --cap-add $cap"
    done
fi

if [ -n "$CAP_DROP" ]; then
    for cap in $CAP_DROP; do
        CMD="$CMD --cap-drop $cap"
    done
fi

if [ "$READ_ONLY" = "true" ]; then
    CMD="$CMD --read-only"
fi

if [ -n "$SECURITY_OPT" ]; then
    CMD="$CMD --security-opt $SECURITY_OPT"
fi

# ========== 设备映射 ==========
if [ -n "$DEVICES" ]; then
    while IFS= read -r device; do
        [ -z "$device" ] && continue
        CMD="$CMD --device $device"
    done <<< "$DEVICES"
fi

# ========== 系统调用参数 ==========
if [ -n "$SYSCTL_PARAMS" ]; then
    while IFS= read -r param; do
        [ -z "$param" ] && continue
        CMD="$CMD --sysctl $param"
    done <<< "$SYSCTL_PARAMS"
fi

# ========== Ulimit 配置 ==========
if [ -n "$ULIMIT_NOFILE" ]; then
    CMD="$CMD --ulimit nofile=$ULIMIT_NOFILE"
fi

if [ -n "$ULIMIT_NPROC" ]; then
    CMD="$CMD --ulimit nproc=$ULIMIT_NPROC"
fi

# ========== 容器标签 ==========
if [ -n "$LABELS" ]; then
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        CMD="$CMD --label $label"
    done <<< "$LABELS"
fi

# ========== 命名空间 ==========
if [ -n "$PID_MODE" ]; then
    CMD="$CMD --pid $PID_MODE"
fi

if [ -n "$IPC_MODE" ]; then
    CMD="$CMD --ipc $IPC_MODE"
fi

if [ -n "$UTS_MODE" ]; then
    CMD="$CMD --uts $UTS_MODE"
fi

# ========== 额外参数 ==========
if [ -n "$EXTRA_DOCKER_ARGS" ]; then
    CMD="$CMD $EXTRA_DOCKER_ARGS"
fi

# ========== 镜像名称 ==========
CMD="$CMD $IMAGE_NAME"

# ========== 容器命令 ==========
if [ -n "$CONTAINER_CMD" ]; then
    CMD="$CMD $CONTAINER_CMD"
fi

###############################################################################
# 执行命令
###############################################################################

echo ""
echo "执行命令:"
echo "$CMD"
echo ""

# 执行 docker run
eval "$CMD"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 容器创建成功!"
    exit 0
else
    echo ""
    echo "✗ 容器创建失败!"
    exit 1
fi

