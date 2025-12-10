#!/usr/bin/env bash
#
# install-docker-offline.sh - 企业级Docker离线安装脚本
# 支持: CentOS 7/8/9/Stream, Ubuntu 20.04/22.04/24.04
# 功能: 从离线包安装Docker Engine + Docker Compose
#
# 使用方法:
#   sudo ./install-docker-offline.sh [离线包目录]
#   sudo ./install-docker-offline.sh /opt/docker-offline-27.4.1-centos8-amd64
#

set -euo pipefail

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# ==================== 权限检查 ====================
if [[ $EUID -ne 0 ]]; then
   log_error "此脚本需要root权限运行"
   echo "请使用: sudo $0"
   exit 1
fi

# ==================== 参数处理 ====================
PACKAGE_DIR="${1:-.}"

# 如果目录不存在,显示帮助
if [[ ! -d "$PACKAGE_DIR" ]]; then
    log_error "目录不存在: $PACKAGE_DIR"
    echo ""
    echo "使用方法:"
    echo "  $0 [离线包目录]"
    echo ""
    echo "示例:"
    echo "  $0 ./docker-offline-27.4.1-centos8-amd64"
    echo "  $0 /opt/docker-offline-27.4.1-ubuntu22.04-amd64"
    exit 1
fi

PACKAGE_DIR="$(cd "$PACKAGE_DIR" && pwd)"

log_info "=== Docker离线安装 ==="
log_info "安装目录: $PACKAGE_DIR"
echo ""

# ==================== 系统检测 ====================
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi

    case "$OS_TYPE" in
        centos|rhel|rocky|almalinux)
            OS_FAMILY="rhel"
            PACKAGE_MANAGER="yum"
            if command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
            fi
            ;;
        ubuntu|debian)
            OS_FAMILY="debian"
            PACKAGE_MANAGER="apt"
            ;;
        *)
            log_error "不支持的操作系统: $OS_TYPE"
            exit 1
            ;;
    esac

    log_info "检测到系统: $OS_TYPE $OS_VERSION ($OS_FAMILY)"
}

# ==================== 检查可用的安装包 ====================
check_packages() {
    HAS_RPMS=false
    HAS_DEBS=false
    HAS_STATIC=false

    if [[ -d "$PACKAGE_DIR/rpms" ]] && ls "$PACKAGE_DIR"/rpms/*.rpm >/dev/null 2>&1; then
        HAS_RPMS=true
        log_info "发现RPM包"
    fi

    if [[ -d "$PACKAGE_DIR/debs" ]] && ls "$PACKAGE_DIR"/debs/*.deb >/dev/null 2>&1; then
        HAS_DEBS=true
        log_info "发现DEB包"
    fi

    if [[ -d "$PACKAGE_DIR/static" ]] && ls "$PACKAGE_DIR"/static/docker-*.tgz >/dev/null 2>&1; then
        HAS_STATIC=true
        log_info "发现静态二进制包"
    fi

    if ! $HAS_RPMS && ! $HAS_DEBS && ! $HAS_STATIC; then
        log_error "未找到任何可安装的包"
        log_error "请确保离线包目录包含 rpms/, debs/ 或 static/ 目录"
        exit 1
    fi
}

# ==================== RPM安装 ====================
install_rpm() {
    log_info "=== 使用RPM包安装 ==="
    
    # 卸载旧版本
    log_info "卸载旧版本..."
    $PACKAGE_MANAGER remove -y \
        docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine \
        podman \
        runc 2>/dev/null || true
    
    # 安装RPM包
    log_info "安装Docker RPM包..."
    
    # 先尝试使用包管理器安装(会处理依赖)
    if command -v $PACKAGE_MANAGER >/dev/null 2>&1; then
        $PACKAGE_MANAGER install -y "$PACKAGE_DIR"/rpms/*.rpm 2>/dev/null || {
            log_warn "包管理器安装失败,尝试rpm直接安装..."
            rpm -Uvh --force --nodeps "$PACKAGE_DIR"/rpms/*.rpm || {
                log_error "RPM包安装失败"
                return 1
            }
        }
    else
        rpm -Uvh --force --nodeps "$PACKAGE_DIR"/rpms/*.rpm || {
            log_error "RPM包安装失败"
            return 1
        }
    fi
    
    # 配置Docker
    configure_docker
    
    # 启动服务
    log_info "启动Docker服务..."
    systemctl daemon-reload
    systemctl enable docker
    systemctl enable containerd 2>/dev/null || true
    systemctl start containerd 2>/dev/null || true
    systemctl start docker
    
    log_success "RPM安装完成"
    return 0
}

# ==================== DEB安装 ====================
install_deb() {
    log_info "=== 使用DEB包安装 ==="
    
    # 卸载旧版本
    log_info "卸载旧版本..."
    apt-get remove -y \
        docker \
        docker-engine \
        docker.io \
        containerd \
        runc 2>/dev/null || true
    
    # 安装DEB包
    log_info "安装Docker DEB包..."
    
    dpkg -i "$PACKAGE_DIR"/debs/*.deb 2>/dev/null || {
        log_warn "dpkg安装遇到依赖问题,尝试修复..."
        apt-get update 2>/dev/null || true
        apt-get -f install -y 2>/dev/null || {
            log_warn "无法自动修复依赖,继续安装..."
        }
        dpkg -i "$PACKAGE_DIR"/debs/*.deb || {
            log_error "DEB包安装失败"
            return 1
        }
    }
    
    # 配置Docker
    configure_docker
    
    # 启动服务
    log_info "启动Docker服务..."
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker
    
    log_success "DEB安装完成"
    return 0
}

# ==================== 静态二进制安装 ====================
install_static() {
    log_info "=== 使用静态二进制安装 ==="
    
    # 查找Docker tarball
    DOCKER_TGZ=$(ls "$PACKAGE_DIR"/static/docker-*.tgz 2>/dev/null | head -1)
    
    if [[ -z "$DOCKER_TGZ" ]]; then
        log_error "未找到Docker静态二进制包"
        return 1
    fi
    
    log_info "解压Docker: $(basename "$DOCKER_TGZ")"
    
    # 创建临时目录
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT
    
    # 解压
    tar -xzf "$DOCKER_TGZ" -C "$tmpdir"
    
    # 查找二进制文件目录
    if [[ -d "$tmpdir/docker" ]]; then
        BIN_SRC="$tmpdir/docker"
    else
        BIN_SRC="$tmpdir"
    fi
    
    # 停止旧的Docker服务(如果存在)
    systemctl stop docker 2>/dev/null || true
    systemctl stop containerd 2>/dev/null || true
    
    # 安装二进制文件
    log_info "安装Docker二进制文件到 /usr/bin ..."
    mkdir -p /usr/bin
    
    for binary in "$BIN_SRC"/*; do
        if [[ -f "$binary" ]] && [[ -x "$binary" ]]; then
            cp -f "$binary" /usr/bin/
            log_success "已安装: $(basename "$binary")"
        fi
    done
    
    # 安装Docker Compose
    if [[ -f "$PACKAGE_DIR/static/docker-compose" ]]; then
        log_info "安装Docker Compose..."
        
        # 作为插件安装
        mkdir -p /usr/local/lib/docker/cli-plugins
        cp -f "$PACKAGE_DIR/static/docker-compose" /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        log_success "Compose插件已安装"
        
        # 也安装到标准路径(兼容旧版本)
        cp -f "$PACKAGE_DIR/static/docker-compose" /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_success "Compose二进制已安装"
    fi
    
    # 配置Docker
    configure_docker
    
    # 创建systemd服务
    create_systemd_services
    
    # 启动服务
    log_info "启动Docker服务..."
    systemctl daemon-reload
    systemctl enable containerd 2>/dev/null || true
    systemctl start containerd 2>/dev/null || true
    systemctl enable docker.socket 2>/dev/null || true
    systemctl start docker.socket 2>/dev/null || true
    systemctl enable docker
    systemctl start docker
    
    log_success "静态二进制安装完成"
    return 0
}

# ==================== 配置Docker ====================
configure_docker() {
    log_info "配置Docker..."
    
    # 创建配置目录
    mkdir -p /etc/docker
    
    # 创建默认配置文件(如果不存在)
    if [[ ! -f /etc/docker/daemon.json ]]; then
        log_info "创建默认daemon.json配置"
        cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
        log_success "配置文件已创建"
    else
        log_info "配置文件已存在,保持不变"
    fi
}

# ==================== 创建systemd服务 ====================
create_systemd_services() {
    log_info "创建systemd服务文件..."
    
    # 创建docker组
    groupadd docker 2>/dev/null || true
    
    # containerd服务
    if command -v containerd >/dev/null 2>&1 || [[ -f /usr/bin/containerd ]]; then
        log_info "创建containerd服务..."
        cat > /etc/systemd/system/containerd.service <<'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
        log_success "containerd服务已创建"
    fi
    
    # docker.socket
    log_info "创建docker.socket..."
    cat > /etc/systemd/system/docker.socket <<'EOF'
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF
    log_success "docker.socket已创建"
    
    # docker服务
    log_info "创建docker.service..."
    cat > /etc/systemd/system/docker.service <<'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket containerd.service

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF
    log_success "docker.service已创建"
}

# ==================== 验证安装 ====================
verify_installation() {
    log_info "=== 验证安装 ==="
    echo ""
    
    # 检查Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker命令未找到"
        return 1
    fi
    
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "未知")
    log_success "Docker: $DOCKER_VERSION"
    
    # 等待Docker启动
    log_info "等待Docker服务启动..."
    local max_wait=30
    local wait_count=0
    while ! docker info >/dev/null 2>&1; do
        sleep 1
        ((wait_count++))
        if [[ $wait_count -ge $max_wait ]]; then
            log_error "Docker服务启动超时"
            log_info "请检查: systemctl status docker"
            return 1
        fi
    done
    
    log_success "Docker服务运行正常"
    
    # 检查Docker Compose
    echo ""
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version 2>/dev/null || echo "未知")
        log_success "Docker Compose (插件): $COMPOSE_VERSION"
    fi
    
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || echo "未知")
        log_success "Docker Compose (二进制): $COMPOSE_VERSION"
    fi
    
    # 运行测试容器
    echo ""
    log_info "运行测试容器..."
    if docker run --rm hello-world >/dev/null 2>&1; then
        log_success "Docker运行测试通过"
    else
        log_warn "Docker测试容器运行失败 (可能需要外网访问)"
    fi
    
    return 0
}

# ==================== 显示后续步骤 ====================
show_next_steps() {
    echo ""
    log_success "=== 安装完成 ==="
    echo ""
    log_info "后续步骤:"
    echo ""
    echo "1. 将当前用户添加到docker组 (可选,避免每次使用sudo):"
    echo "   sudo usermod -aG docker \$USER"
    echo "   newgrp docker"
    echo ""
    echo "2. 验证安装:"
    echo "   docker --version"
    echo "   docker info"
    echo "   docker compose version"
    echo ""
    echo "3. 运行第一个容器:"
    echo "   docker run --rm hello-world"
    echo ""
    echo "4. 查看帮助:"
    echo "   docker --help"
    echo "   docker compose --help"
    echo ""
    
    log_info "提示:"
    echo "  - Docker配置文件: /etc/docker/daemon.json"
    echo "  - 查看服务状态: systemctl status docker"
    echo "  - 查看日志: journalctl -xeu docker"
    echo ""
}

# ==================== 主流程 ====================
main() {
    detect_os
    check_packages
    
    echo ""
    log_info "开始安装..."
    echo ""
    
    INSTALL_SUCCESS=false
    
    # 根据系统类型和可用包选择安装方式
    if [[ "$OS_FAMILY" == "rhel" ]] && $HAS_RPMS; then
        install_rpm && INSTALL_SUCCESS=true
    elif [[ "$OS_FAMILY" == "debian" ]] && $HAS_DEBS; then
        install_deb && INSTALL_SUCCESS=true
    elif $HAS_STATIC; then
        log_info "使用静态二进制安装(通用方式)"
        install_static && INSTALL_SUCCESS=true
    else
        log_error "没有适合当前系统的安装包"
        log_error "系统: $OS_FAMILY, 可用包: RPM=$HAS_RPMS, DEB=$HAS_DEBS, STATIC=$HAS_STATIC"
        exit 1
    fi
    
    if ! $INSTALL_SUCCESS; then
        log_error "安装失败"
        exit 1
    fi
    
    # 验证安装
    verify_installation || {
        log_error "安装验证失败"
        exit 1
    }
    
    # 显示后续步骤
    show_next_steps
}

# 执行主流程
main "$@"

