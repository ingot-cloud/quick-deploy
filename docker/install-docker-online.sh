#!/usr/bin/env bash
#
# install-docker-online.sh - 企业级在线Docker安装脚本
# 支持: CentOS 7/8/9/Stream, Ubuntu 20.04/22.04/24.04
# 功能: 安装Docker Engine + Docker Compose (插件或二进制)
#
# 使用方法:
#   交互式: sudo ./install-docker-online.sh
#   非交互式: sudo ./install-docker-online.sh --docker-version 27.4.1 --compose-version v2.30.3 --compose-mode plugin
#

set -euo pipefail

# ==================== 默认配置 ====================
DEFAULT_DOCKER_VERSION="27.4.1"
DEFAULT_COMPOSE_VERSION="v2.30.3"
DEFAULT_COMPOSE_MODE="plugin"  # plugin | binary | both

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# ==================== 系统检测 ====================
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE=$ID
        OS_VERSION=$VERSION_ID
        OS_CODENAME=${VERSION_CODENAME:-}
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

    # 检测架构
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            DOCKER_ARCH="x86_64"
            COMPOSE_ARCH="x86_64"
            ;;
        aarch64)
            DOCKER_ARCH="aarch64"
            COMPOSE_ARCH="aarch64"
            ;;
        arm64)
            DOCKER_ARCH="aarch64"
            COMPOSE_ARCH="aarch64"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac

    log_info "检测到系统: $OS_TYPE $OS_VERSION ($OS_FAMILY) - $ARCH"
}

# ==================== 参数解析 ====================
parse_args() {
    INTERACTIVE=true
    DOCKER_VERSION="$DEFAULT_DOCKER_VERSION"
    COMPOSE_VERSION="$DEFAULT_COMPOSE_VERSION"
    COMPOSE_MODE="$DEFAULT_COMPOSE_MODE"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --docker-version)
                DOCKER_VERSION="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --compose-version)
                COMPOSE_VERSION="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --compose-mode)
                COMPOSE_MODE="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            -h|--help)
                cat <<EOF
使用方法: $0 [选项]

选项:
    --docker-version VERSION    Docker版本 (默认: $DEFAULT_DOCKER_VERSION)
    --compose-version VERSION   Docker Compose版本 (默认: $DEFAULT_COMPOSE_VERSION)
    --compose-mode MODE         Compose安装模式: plugin|binary|both (默认: $DEFAULT_COMPOSE_MODE)
    --non-interactive           非交互模式
    -h, --help                  显示帮助信息

示例:
    # 交互式安装
    sudo $0

    # 非交互式安装指定版本
    sudo $0 --docker-version 27.4.1 --compose-version v2.30.3 --compose-mode plugin
EOF
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
}

# ==================== 交互式输入 ====================
interactive_input() {
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo ""
        log_info "=== Docker在线安装配置 ==="
        echo ""
        
        read -rp "Docker版本 [$DEFAULT_DOCKER_VERSION]: " input
        DOCKER_VERSION="${input:-$DEFAULT_DOCKER_VERSION}"
        
        read -rp "Docker Compose版本 [$DEFAULT_COMPOSE_VERSION]: " input
        COMPOSE_VERSION="${input:-$DEFAULT_COMPOSE_VERSION}"
        
        echo ""
        echo "Compose安装模式:"
        echo "  1) plugin  - 作为Docker插件安装 (推荐)"
        echo "  2) binary  - 作为独立二进制安装"
        echo "  3) both    - 同时安装插件和二进制"
        read -rp "选择 [1]: " choice
        case $choice in
            2) COMPOSE_MODE="binary" ;;
            3) COMPOSE_MODE="both" ;;
            *) COMPOSE_MODE="plugin" ;;
        esac
        
        echo ""
        log_info "配置总结:"
        echo "  - Docker版本: $DOCKER_VERSION"
        echo "  - Compose版本: $COMPOSE_VERSION"
        echo "  - Compose模式: $COMPOSE_MODE"
        echo ""
        read -rp "确认安装? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_warn "安装已取消"
            exit 0
        fi
    fi
}

# ==================== 卸载旧版本 ====================
remove_old_docker() {
    log_info "检查并卸载旧版本Docker..."
    
    if [[ "$OS_FAMILY" == "rhel" ]]; then
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
    else
        apt-get remove -y \
            docker \
            docker-engine \
            docker.io \
            containerd \
            runc 2>/dev/null || true
    fi
    
    log_success "旧版本清理完成"
}

# ==================== 安装依赖 ====================
install_dependencies() {
    log_info "安装系统依赖..."
    
    if [[ "$OS_FAMILY" == "rhel" ]]; then
        $PACKAGE_MANAGER install -y \
            yum-utils \
            device-mapper-persistent-data \
            lvm2 \
            curl \
            ca-certificates
    else
        apt-get update
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
    fi
    
    log_success "依赖安装完成"
}

# ==================== 添加Docker仓库 ====================
add_docker_repo() {
    log_info "添加Docker官方仓库..."
    
    if [[ "$OS_FAMILY" == "rhel" ]]; then
        # 添加Docker仓库
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        # 如果是CentOS 8+, 可能需要额外配置
        if [[ "$OS_TYPE" == "centos" ]] && [[ "${OS_VERSION%%.*}" -ge 8 ]]; then
            $PACKAGE_MANAGER config-manager --set-enabled docker-ce-stable 2>/dev/null || true
        fi
    else
        # Ubuntu/Debian
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$OS_TYPE/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS_TYPE \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update
    fi
    
    log_success "Docker仓库添加完成"
}

# ==================== 安装Docker ====================
install_docker() {
    log_info "安装Docker Engine..."
    
    if [[ "$OS_FAMILY" == "rhel" ]]; then
        # 如果指定了版本,尝试安装特定版本
        if [[ "$DOCKER_VERSION" != "latest" ]]; then
            VERSION_STRING="${DOCKER_VERSION}-1.el${OS_VERSION%%.*}"
            $PACKAGE_MANAGER install -y \
                docker-ce-${VERSION_STRING} \
                docker-ce-cli-${VERSION_STRING} \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin 2>/dev/null || {
                    log_warn "特定版本安装失败,尝试安装最新版本..."
                    $PACKAGE_MANAGER install -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin
                }
        else
            $PACKAGE_MANAGER install -y \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin
        fi
    else
        # Ubuntu/Debian
        if [[ "$DOCKER_VERSION" != "latest" ]]; then
            VERSION_STRING="5:${DOCKER_VERSION}-1~${OS_TYPE}${OS_VERSION}~${OS_CODENAME}"
            apt-get install -y \
                docker-ce=${VERSION_STRING} \
                docker-ce-cli=${VERSION_STRING} \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin 2>/dev/null || {
                    log_warn "特定版本安装失败,尝试安装最新版本..."
                    apt-get install -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin
                }
        else
            apt-get install -y \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin
        fi
    fi
    
    log_success "Docker Engine安装完成"
}

# ==================== 配置Docker ====================
configure_docker() {
    log_info "配置Docker..."
    
    # 创建配置目录
    mkdir -p /etc/docker
    
    # 如果配置文件不存在,创建默认配置
    if [[ ! -f /etc/docker/daemon.json ]]; then
        cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
        log_success "已创建默认daemon.json配置"
    else
        log_info "daemon.json已存在,跳过创建"
    fi
    
    # 启动Docker服务
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker服务已启动并设置为开机自启"
}

# ==================== 安装Docker Compose ====================
install_docker_compose() {
    log_info "安装Docker Compose ($COMPOSE_MODE模式)..."
    
    # 确保版本号格式正确 (带v前缀)
    if [[ ! "$COMPOSE_VERSION" =~ ^v ]]; then
        COMPOSE_VERSION="v${COMPOSE_VERSION}"
    fi
    
    COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}"
    
    case "$COMPOSE_MODE" in
        plugin|both)
            log_info "安装Docker Compose插件..."
            PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"
            mkdir -p "$PLUGIN_DIR"
            
            if curl -fsSL "$COMPOSE_URL" -o "${PLUGIN_DIR}/docker-compose"; then
                chmod +x "${PLUGIN_DIR}/docker-compose"
                log_success "Docker Compose插件安装完成"
            else
                log_error "Docker Compose插件安装失败"
            fi
            ;;
    esac
    
    case "$COMPOSE_MODE" in
        binary|both)
            log_info "安装Docker Compose二进制..."
            if curl -fsSL "$COMPOSE_URL" -o "/usr/local/bin/docker-compose"; then
                chmod +x "/usr/local/bin/docker-compose"
                log_success "Docker Compose二进制安装完成"
            else
                log_error "Docker Compose二进制安装失败"
            fi
            ;;
    esac
}

# ==================== 验证安装 ====================
verify_installation() {
    log_info "验证安装..."
    echo ""
    
    # 验证Docker
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VER=$(docker --version)
        log_success "Docker: $DOCKER_VER"
        
        if docker info >/dev/null 2>&1; then
            log_success "Docker daemon运行正常"
        else
            log_warn "Docker daemon可能未正常运行"
        fi
    else
        log_error "Docker安装失败"
        return 1
    fi
    
    # 验证Docker Compose
    echo ""
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_VER=$(docker compose version)
        log_success "Docker Compose (插件): $COMPOSE_VER"
    fi
    
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VER=$(docker-compose --version)
        log_success "Docker Compose (二进制): $COMPOSE_VER"
    fi
    
    echo ""
    log_info "运行测试容器..."
    if docker run --rm hello-world >/dev/null 2>&1; then
        log_success "Docker运行测试通过"
    else
        log_warn "Docker测试容器运行失败"
    fi
    
    echo ""
    log_success "=== 安装完成 ==="
    echo ""
    log_info "提示:"
    echo "  - 将用户添加到docker组: sudo usermod -aG docker \$USER"
    echo "  - 重新登录后生效,或运行: newgrp docker"
    echo "  - 查看Docker信息: docker info"
    echo "  - 查看Compose版本: docker compose version"
}

# ==================== 主流程 ====================
main() {
    log_info "=== Docker在线安装脚本 ==="
    echo ""
    
    detect_os
    parse_args "$@"
    interactive_input
    
    echo ""
    log_info "开始安装..."
    echo ""
    
    remove_old_docker
    install_dependencies
    add_docker_repo
    install_docker
    configure_docker
    install_docker_compose
    verify_installation
}

# 执行主流程
main "$@"

