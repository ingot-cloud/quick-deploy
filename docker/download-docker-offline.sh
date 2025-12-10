#!/usr/bin/env bash
#
# download-docker-offline.sh - 企业级Docker离线包下载脚本
# 支持在Mac或Linux上运行,下载指定版本的Docker离线安装包
# 支持: CentOS 7/8/9/Stream, Ubuntu 20.04/22.04/24.04
# 支持架构: amd64(x86_64), arm64(aarch64)
#
# 使用方法:
#   交互式: ./download-docker-offline.sh
#   非交互式: ./download-docker-offline.sh --docker-version 27.4.1 --os-type centos --os-version 8 --arch amd64 --compose-version v2.30.3
#

set -euo pipefail

# ==================== 默认配置 ====================
DEFAULT_DOCKER_VERSION="27.4.1"
DEFAULT_COMPOSE_VERSION="v2.30.3"
DEFAULT_OS_TYPE="centos"
DEFAULT_OS_VERSION="8"
DEFAULT_ARCH="amd64"
DEFAULT_DOWNLOAD_MODE="all"  # all | rpm | deb | static

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

# ==================== 检查依赖 ====================
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq未安装,元数据将以纯文本格式保存"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要的依赖: ${missing_deps[*]}"
        echo ""
        echo "请先安装依赖:"
        echo "  Mac:   brew install curl jq"
        echo "  Linux: sudo apt-get install curl jq  # Ubuntu/Debian"
        echo "         sudo yum install curl jq      # CentOS/RHEL"
        exit 1
    fi
}

# ==================== 参数解析 ====================
parse_args() {
    INTERACTIVE=true
    DOCKER_VERSION="$DEFAULT_DOCKER_VERSION"
    COMPOSE_VERSION="$DEFAULT_COMPOSE_VERSION"
    OS_TYPE="$DEFAULT_OS_TYPE"
    OS_VERSION="$DEFAULT_OS_VERSION"
    ARCH="$DEFAULT_ARCH"
    DOWNLOAD_MODE="$DEFAULT_DOWNLOAD_MODE"

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
            --os-type)
                OS_TYPE="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --os-version)
                OS_VERSION="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --arch)
                ARCH="$2"
                INTERACTIVE=false
                shift 2
                ;;
            --download-mode)
                DOWNLOAD_MODE="$2"
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
    --os-type TYPE              目标操作系统: centos|ubuntu (默认: $DEFAULT_OS_TYPE)
    --os-version VERSION        操作系统版本 (默认: $DEFAULT_OS_VERSION)
    --arch ARCH                 目标架构: amd64|arm64 (默认: $DEFAULT_ARCH)
    --download-mode MODE        下载模式: all|rpm|deb|static (默认: $DEFAULT_DOWNLOAD_MODE)
    --non-interactive           非交互模式
    -h, --help                  显示帮助信息

示例:
    # 交互式下载
    ./$0

    # 下载CentOS 8 amd64的离线包
    ./$0 --docker-version 27.4.1 --os-type centos --os-version 8 --arch amd64

    # 下载Ubuntu 22.04 arm64的离线包
    ./$0 --docker-version 27.4.1 --os-type ubuntu --os-version 22.04 --arch arm64

    # 只下载静态二进制文件
    ./$0 --download-mode static --arch amd64
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
        log_info "=== Docker离线包下载配置 ==="
        echo ""
        
        read -rp "Docker版本 [$DEFAULT_DOCKER_VERSION]: " input
        DOCKER_VERSION="${input:-$DEFAULT_DOCKER_VERSION}"
        
        read -rp "Docker Compose版本 [$DEFAULT_COMPOSE_VERSION]: " input
        COMPOSE_VERSION="${input:-$DEFAULT_COMPOSE_VERSION}"
        
        echo ""
        echo "目标操作系统:"
        echo "  1) centos"
        echo "  2) ubuntu"
        read -rp "选择 [1]: " choice
        case $choice in
            2) OS_TYPE="ubuntu" ;;
            *) OS_TYPE="centos" ;;
        esac
        
        if [[ "$OS_TYPE" == "centos" ]]; then
            echo ""
            echo "CentOS版本:"
            echo "  1) 7"
            echo "  2) 8 (推荐)"
            echo "  3) 9"
            echo "  4) stream"
            read -rp "选择 [2]: " choice
            case $choice in
                1) OS_VERSION="7" ;;
                3) OS_VERSION="9" ;;
                4) OS_VERSION="stream" ;;
                *) OS_VERSION="8" ;;
            esac
        else
            echo ""
            echo "Ubuntu版本:"
            echo "  1) 20.04"
            echo "  2) 22.04 (推荐)"
            echo "  3) 24.04"
            read -rp "选择 [2]: " choice
            case $choice in
                1) OS_VERSION="20.04" ;;
                3) OS_VERSION="24.04" ;;
                *) OS_VERSION="22.04" ;;
            esac
        fi
        
        echo ""
        echo "目标架构:"
        echo "  1) amd64 (x86_64)"
        echo "  2) arm64 (aarch64)"
        read -rp "选择 [1]: " choice
        case $choice in
            2) ARCH="arm64" ;;
            *) ARCH="amd64" ;;
        esac
        
        echo ""
        echo "下载模式:"
        echo "  1) all    - 下载所有格式 (RPM/DEB + 静态二进制)"
        echo "  2) rpm    - 仅下载RPM包"
        echo "  3) deb    - 仅下载DEB包"
        echo "  4) static - 仅下载静态二进制"
        read -rp "选择 [1]: " choice
        case $choice in
            2) DOWNLOAD_MODE="rpm" ;;
            3) DOWNLOAD_MODE="deb" ;;
            4) DOWNLOAD_MODE="static" ;;
            *) DOWNLOAD_MODE="all" ;;
        esac
        
        echo ""
        log_info "配置总结:"
        echo "  - Docker版本: $DOCKER_VERSION"
        echo "  - Compose版本: $COMPOSE_VERSION"
        echo "  - 目标系统: $OS_TYPE $OS_VERSION"
        echo "  - 目标架构: $ARCH"
        echo "  - 下载模式: $DOWNLOAD_MODE"
        echo ""
        read -rp "确认下载? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_warn "下载已取消"
            exit 0
        fi
    fi
}

# ==================== 架构映射 ====================
map_architecture() {
    case "$ARCH" in
        amd64|x86_64)
            ARCH_NORM="amd64"
            DOCKER_ARCH="x86_64"
            COMPOSE_ARCH="x86_64"
            DEB_ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH_NORM="arm64"
            DOCKER_ARCH="aarch64"
            COMPOSE_ARCH="aarch64"
            DEB_ARCH="arm64"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
}

# ==================== Ubuntu代号映射 ====================
get_ubuntu_codename() {
    case "$OS_VERSION" in
        20.04) echo "focal" ;;
        22.04) echo "jammy" ;;
        24.04) echo "noble" ;;
        *) echo "jammy" ;;
    esac
}

# ==================== 下载函数 ====================
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-文件}"
    
    log_info "下载 $description..."
    echo "  URL: $url"
    
    if curl -fsSL --connect-timeout 10 --max-time 300 --retry 3 --retry-delay 2 "$url" -o "$output"; then
        local size=$(du -h "$output" | cut -f1)
        log_success "下载成功: $output (大小: $size)"
        return 0
    else
        log_warn "下载失败: $url"
        rm -f "$output" 2>/dev/null || true
        return 1
    fi
}

# ==================== 下载RPM包 ====================
download_rpm_packages() {
    log_info "=== 下载RPM包 (CentOS $OS_VERSION) ==="
    
    local rpm_dir="$OUTPUT_DIR/rpms"
    mkdir -p "$rpm_dir"
    
    local base_url="https://download.docker.com/linux/centos"
    local centos_ver="$OS_VERSION"
    
    # CentOS Stream使用9的路径
    if [[ "$OS_VERSION" == "stream" ]]; then
        centos_ver="9"
    fi
    
    local repo_url="${base_url}/${centos_ver}/${DOCKER_ARCH}/stable/Packages"
    
    # Docker包列表: 包名:版本号
    # 注意: containerd, buildx, compose 有独立的版本号,不跟随Docker版本
    # 这些版本号需要定期更新
    local packages=(
        "docker-ce:${DOCKER_VERSION}-1.el${centos_ver}"
        "docker-ce-cli:${DOCKER_VERSION}-1.el${centos_ver}"
        "containerd.io:1.7.22-3.1.el${centos_ver}"
        "docker-buildx-plugin:0.17.1-1.el${centos_ver}"
        "docker-compose-plugin:2.29.7-1.el${centos_ver}"
        "docker-ce-rootless-extras:${DOCKER_VERSION}-1.el${centos_ver}"
    )
    
    local success_count=0
    local total_count=${#packages[@]}
    
    for pkg_info in "${packages[@]}"; do
        local pkg_name="${pkg_info%%:*}"
        local pkg_version="${pkg_info#*:}"
        local filename="${pkg_name}-${pkg_version}.${DOCKER_ARCH}.rpm"
        
        # 尝试下载指定版本
        if download_file "${repo_url}/${filename}" "${rpm_dir}/${filename}" "$pkg_name"; then
            ((success_count++))
            continue
        fi
        
        # 如果指定版本失败,尝试通用版本号(主要用于containerd等)
        if [[ "$pkg_name" == "containerd.io" ]]; then
            log_info "  尝试containerd.io其他版本..."
            local alt_versions=("1.7.22-3.1" "1.7.21-3.1" "1.7.20-3.1" "1.6.33-3.1")
            for alt_ver in "${alt_versions[@]}"; do
                local alt_file="${pkg_name}-${alt_ver}.el${centos_ver}.${DOCKER_ARCH}.rpm"
                if download_file "${repo_url}/${alt_file}" "${rpm_dir}/${alt_file}" "$pkg_name (v${alt_ver})"; then
                    ((success_count++))
                    break
                fi
            done
        elif [[ "$pkg_name" == "docker-buildx-plugin" ]]; then
            log_info "  尝试docker-buildx-plugin其他版本..."
            local alt_versions=("0.17.1-1" "0.17.0-1" "0.16.2-1")
            for alt_ver in "${alt_versions[@]}"; do
                local alt_file="${pkg_name}-${alt_ver}.el${centos_ver}.${DOCKER_ARCH}.rpm"
                if download_file "${repo_url}/${alt_file}" "${rpm_dir}/${alt_file}" "$pkg_name (v${alt_ver})"; then
                    ((success_count++))
                    break
                fi
            done
        elif [[ "$pkg_name" == "docker-compose-plugin" ]]; then
            log_info "  尝试docker-compose-plugin其他版本..."
            local alt_versions=("2.29.7-1" "2.29.6-1" "2.29.2-1" "2.28.1-1")
            for alt_ver in "${alt_versions[@]}"; do
                local alt_file="${pkg_name}-${alt_ver}.el${centos_ver}.${DOCKER_ARCH}.rpm"
                if download_file "${repo_url}/${alt_file}" "${rpm_dir}/${alt_file}" "$pkg_name (v${alt_ver})"; then
                    ((success_count++))
                    break
                fi
            done
        else
            log_warn "  ${pkg_name}: 版本 ${pkg_version} 未找到"
            log_warn "  建议: 访问 ${repo_url}/ 查看可用版本"
        fi
    done
    
    if [[ $success_count -gt 0 ]]; then
        log_success "RPM包下载完成 ($success_count/$total_count 个包)"
        if [[ $success_count -lt $total_count ]]; then
            log_warn "部分包下载失败,但已下载的包可能足够安装基础Docker"
        fi
        return 0
    else
        log_error "RPM包下载失败"
        log_warn "提示: 可以使用 --download-mode static 下载静态二进制,不依赖特定包版本"
        return 1
    fi
}

# ==================== 下载DEB包 ====================
download_deb_packages() {
    log_info "=== 下载DEB包 (Ubuntu $OS_VERSION) ==="
    
    local deb_dir="$OUTPUT_DIR/debs"
    mkdir -p "$deb_dir"
    
    local codename=$(get_ubuntu_codename)
    local base_url="https://download.docker.com/linux/ubuntu/dists/${codename}/pool/stable/${DEB_ARCH}"
    
    # Docker包列表: 包名和文件名
    # 注意: DEB文件名使用下划线分隔,且版本号中不包含epoch前缀(5:)
    local packages=(
        "docker-ce:docker-ce_${DOCKER_VERSION}-1~ubuntu.${OS_VERSION}~${codename}_${DEB_ARCH}.deb"
        "docker-ce-cli:docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.${OS_VERSION}~${codename}_${DEB_ARCH}.deb"
        "containerd.io:containerd.io_1.7.24-1_${DEB_ARCH}.deb"
        "docker-buildx-plugin:docker-buildx-plugin_0.19.3-1~ubuntu.${OS_VERSION}~${codename}_${DEB_ARCH}.deb"
        "docker-compose-plugin:docker-compose-plugin_2.32.1-1~ubuntu.${OS_VERSION}~${codename}_${DEB_ARCH}.deb"
        "docker-ce-rootless-extras:docker-ce-rootless-extras_${DOCKER_VERSION}-1~ubuntu.${OS_VERSION}~${codename}_${DEB_ARCH}.deb"
    )
    
    local success_count=0
    
    for pkg_info in "${packages[@]}"; do
        local pkg_name="${pkg_info%%:*}"
        local pkg_file="${pkg_info#*:}"
        
        if download_file "${base_url}/${pkg_file}" "${deb_dir}/${pkg_file}" "$pkg_name"; then
            ((success_count++))
        else
            # 尝试不同的版本号格式(某些包可能版本号不同)
            log_warn "  ${pkg_name}: 特定版本未找到,尝试其他版本..."
            
            # 对于插件包,尝试latest标签或通配符匹配
            # 这里只是警告,因为在离线下载时无法动态查询
            log_warn "  建议: 访问 ${base_url}/ 查看可用的 ${pkg_name} 版本"
        fi
    done
    
    if [[ $success_count -gt 0 ]]; then
        log_success "DEB包下载完成 ($success_count/${#packages[@]} 个包)"
        return 0
    else
        log_error "DEB包下载失败"
        log_warn "提示: 可以使用 --download-mode static 下载静态二进制,不依赖特定包版本"
        return 1
    fi
}

# ==================== 下载静态二进制 ====================
download_static_binaries() {
    log_info "=== 下载静态二进制文件 ==="
    
    local static_dir="$OUTPUT_DIR/static"
    mkdir -p "$static_dir"
    
    local success=false
    
    # 下载Docker静态二进制
    local docker_url="https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz"
    if download_file "$docker_url" "${static_dir}/docker-${DOCKER_VERSION}.tgz" "Docker Engine"; then
        success=true
    fi
    
    # 确保Compose版本格式正确
    local compose_ver="$COMPOSE_VERSION"
    if [[ ! "$compose_ver" =~ ^v ]]; then
        compose_ver="v${compose_ver}"
    fi
    
    # 下载Docker Compose二进制
    local compose_url="https://github.com/docker/compose/releases/download/${compose_ver}/docker-compose-linux-${COMPOSE_ARCH}"
    if download_file "$compose_url" "${static_dir}/docker-compose" "Docker Compose"; then
        chmod +x "${static_dir}/docker-compose"
        success=true
    fi
    
    # 下载containerd (可选,Docker静态包中已包含)
    # 这里我们可以额外下载独立的containerd
    local containerd_version="1.7.24"
    local containerd_url="https://github.com/containerd/containerd/releases/download/v${containerd_version}/containerd-${containerd_version}-linux-${ARCH_NORM}.tar.gz"
    if download_file "$containerd_url" "${static_dir}/containerd-${containerd_version}.tar.gz" "containerd (可选)"; then
        success=true
    fi
    
    if $success; then
        log_success "静态二进制文件下载完成"
        return 0
    else
        log_error "静态二进制文件下载失败"
        return 1
    fi
}

# ==================== 创建安装脚本 ====================
create_install_script() {
    log_info "创建安装脚本..."
    
    cat > "$OUTPUT_DIR/install.sh" <<'INSTALL_SCRIPT'
#!/usr/bin/env bash
#
# Docker离线安装脚本 (自动生成)
# 使用方法: sudo ./install.sh
#

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "错误: 此脚本需要root权限运行"
   echo "请使用: sudo $0"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Docker离线安装 ==="
echo "安装目录: $SCRIPT_DIR"
echo ""

# 检测系统类型
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_TYPE=$ID
elif command -v rpm >/dev/null 2>&1; then
    OS_TYPE="centos"
elif command -v dpkg >/dev/null 2>&1; then
    OS_TYPE="ubuntu"
else
    echo "错误: 无法检测操作系统类型"
    exit 1
fi

# RPM系统安装
if [[ "$OS_TYPE" =~ ^(centos|rhel|rocky|almalinux)$ ]] && [[ -d "$SCRIPT_DIR/rpms" ]] && ls "$SCRIPT_DIR"/rpms/*.rpm >/dev/null 2>&1; then
    echo "检测到RPM系统,使用RPM包安装..."
    
    # 安装所有RPM包
    rpm -Uvh --force --nodeps "$SCRIPT_DIR"/rpms/*.rpm || {
        echo "警告: 部分包安装失败,尝试使用yum/dnf修复依赖..."
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y "$SCRIPT_DIR"/rpms/*.rpm 2>/dev/null || true
        elif command -v yum >/dev/null 2>&1; then
            yum install -y "$SCRIPT_DIR"/rpms/*.rpm 2>/dev/null || true
        fi
    }
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable --now docker
    systemctl enable --now containerd || true
    
    echo "RPM安装完成"

# DEB系统安装
elif [[ "$OS_TYPE" =~ ^(ubuntu|debian)$ ]] && [[ -d "$SCRIPT_DIR/debs" ]] && ls "$SCRIPT_DIR"/debs/*.deb >/dev/null 2>&1; then
    echo "检测到DEB系统,使用DEB包安装..."
    
    # 安装所有DEB包
    dpkg -i "$SCRIPT_DIR"/debs/*.deb || {
        echo "警告: 部分包安装失败,尝试修复依赖..."
        apt-get update 2>/dev/null || true
        apt-get -f install -y 2>/dev/null || true
    }
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable --now docker
    
    echo "DEB安装完成"

# 静态二进制安装
elif [[ -d "$SCRIPT_DIR/static" ]] && ls "$SCRIPT_DIR"/static/docker-*.tgz >/dev/null 2>&1; then
    echo "使用静态二进制安装..."
    
    # 解压Docker
    DOCKER_TGZ=$(ls "$SCRIPT_DIR"/static/docker-*.tgz | head -1)
    echo "解压: $DOCKER_TGZ"
    
    tmpdir=$(mktemp -d)
    tar -xzf "$DOCKER_TGZ" -C "$tmpdir"
    
    # 复制二进制文件
    echo "安装Docker二进制到 /usr/bin ..."
    cp -f "$tmpdir/docker/"* /usr/bin/
    
    # 清理临时目录
    rm -rf "$tmpdir"
    
    # 安装Docker Compose
    if [[ -f "$SCRIPT_DIR/static/docker-compose" ]]; then
        echo "安装Docker Compose..."
        # 作为插件安装
        mkdir -p /usr/local/lib/docker/cli-plugins
        cp -f "$SCRIPT_DIR/static/docker-compose" /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        
        # 也复制到标准路径
        cp -f "$SCRIPT_DIR/static/docker-compose" /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # 创建Docker配置
    mkdir -p /etc/docker
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
    fi
    
    # 创建systemd服务文件
    echo "创建systemd服务..."
    
    # containerd服务
    if command -v containerd >/dev/null 2>&1; then
        cat > /etc/systemd/system/containerd.service <<'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # docker服务
    cat > /etc/systemd/system/docker.service <<'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target containerd.service
Wants=network-online.target
Requires=docker.socket

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

    # docker socket
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
    
    # 创建docker组
    groupadd docker 2>/dev/null || true
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable --now containerd 2>/dev/null || true
    systemctl enable --now docker.socket
    systemctl enable --now docker
    
    echo "静态二进制安装完成"

else
    echo "错误: 未找到可安装的包 (rpms/debs/static)"
    exit 1
fi

# 验证安装
echo ""
echo "=== 验证安装 ==="
if command -v docker >/dev/null 2>&1; then
    echo "Docker版本: $(docker --version)"
    
    # 等待Docker启动
    sleep 2
    
    if docker info >/dev/null 2>&1; then
        echo "Docker服务: 运行正常"
    else
        echo "警告: Docker服务可能未正常运行,请检查: systemctl status docker"
    fi
else
    echo "错误: Docker未安装成功"
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose (插件): $(docker compose version)"
elif command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose (二进制): $(docker-compose --version)"
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "提示:"
echo "  - 将用户添加到docker组: sudo usermod -aG docker \$USER"
echo "  - 重新登录后生效"
echo "  - 查看Docker信息: docker info"
INSTALL_SCRIPT

    chmod +x "$OUTPUT_DIR/install.sh"
    log_success "安装脚本已创建: $OUTPUT_DIR/install.sh"
}

# ==================== 生成元数据 ====================
generate_metadata() {
    log_info "生成元数据文件..."
    
    local metadata_file="$OUTPUT_DIR/metadata.json"
    
    cat > "$metadata_file" <<EOF
{
  "docker_version": "$DOCKER_VERSION",
  "compose_version": "$COMPOSE_VERSION",
  "os_type": "$OS_TYPE",
  "os_version": "$OS_VERSION",
  "architecture": "$ARCH_NORM",
  "download_mode": "$DOWNLOAD_MODE",
  "generated_at": "$(date -Iseconds 2>/dev/null || date)",
  "generated_on": "$(uname -s) $(uname -m)"
}
EOF
    
    # 也生成一个README
    cat > "$OUTPUT_DIR/README.md" <<EOF
# Docker 离线安装包

## 包信息

- **Docker版本**: $DOCKER_VERSION
- **Compose版本**: $COMPOSE_VERSION
- **目标系统**: $OS_TYPE $OS_VERSION
- **目标架构**: $ARCH_NORM
- **生成时间**: $(date)

## 安装说明

### 1. 传输到目标机器

将整个目录复制到目标机器:

\`\`\`bash
scp -r $(basename "$OUTPUT_DIR") user@target-host:/opt/
\`\`\`

### 2. 执行安装

在目标机器上:

\`\`\`bash
cd /opt/$(basename "$OUTPUT_DIR")
sudo ./install.sh
\`\`\`

### 3. 验证安装

\`\`\`bash
docker --version
docker compose version
docker run --rm hello-world
\`\`\`

### 4. 用户配置

将当前用户添加到docker组:

\`\`\`bash
sudo usermod -aG docker \$USER
newgrp docker
\`\`\`

## 目录结构

- \`rpms/\` - RPM包 (CentOS/RHEL系统)
- \`debs/\` - DEB包 (Ubuntu/Debian系统)
- \`static/\` - 静态二进制文件 (通用)
- \`install.sh\` - 自动安装脚本
- \`metadata.json\` - 包元数据
- \`README.md\` - 本文件

## 故障排查

### Docker服务无法启动

\`\`\`bash
sudo systemctl status docker
sudo journalctl -xeu docker
\`\`\`

### 权限问题

确保当前用户在docker组中:

\`\`\`bash
groups \$USER
\`\`\`

### 网络问题

检查防火墙设置:

\`\`\`bash
sudo systemctl status firewalld
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
\`\`\`

## 支持

如有问题,请联系系统管理员。
EOF
    
    log_success "元数据文件已生成"
}

# ==================== 主流程 ====================
main() {
    log_info "=== Docker离线包下载脚本 ==="
    echo ""
    
    check_dependencies
    parse_args "$@"
    interactive_input
    map_architecture
    
    # 创建输出目录
    OUTPUT_DIR="docker-offline-${DOCKER_VERSION}-${OS_TYPE}${OS_VERSION}-${ARCH_NORM}"
    mkdir -p "$OUTPUT_DIR"
    
    echo ""
    log_info "输出目录: $OUTPUT_DIR"
    log_info "开始下载..."
    echo ""
    
    local download_success=false
    
    # 根据模式下载
    case "$DOWNLOAD_MODE" in
        all)
            if [[ "$OS_TYPE" == "centos" ]]; then
                download_rpm_packages && download_success=true
            elif [[ "$OS_TYPE" == "ubuntu" ]]; then
                download_deb_packages && download_success=true
            fi
            download_static_binaries && download_success=true
            ;;
        rpm)
            download_rpm_packages && download_success=true
            ;;
        deb)
            download_deb_packages && download_success=true
            ;;
        static)
            download_static_binaries && download_success=true
            ;;
    esac
    
    if ! $download_success; then
        log_error "下载失败"
        exit 1
    fi
    
    # 创建安装脚本和元数据
    create_install_script
    generate_metadata
    
    # 显示目录内容
    echo ""
    log_info "=== 下载完成 ==="
    echo ""
    log_info "输出目录: $OUTPUT_DIR"
    echo ""
    
    if command -v tree >/dev/null 2>&1; then
        tree -h "$OUTPUT_DIR" || ls -lhR "$OUTPUT_DIR"
    else
        ls -lhR "$OUTPUT_DIR"
    fi
    
    echo ""
    log_success "离线包已准备完成!"
    echo ""
    log_info "下一步:"
    echo "  1. 将 $OUTPUT_DIR 目录传输到目标机器"
    echo "  2. 在目标机器上运行: sudo $OUTPUT_DIR/install.sh"
    echo ""
    log_info "详细说明请查看: $OUTPUT_DIR/README.md"
}

# 执行主流程
main "$@"

