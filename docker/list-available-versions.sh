#!/usr/bin/env bash
#
# list-available-versions.sh - 查询Docker官方仓库中可用的版本
# 帮助用户了解特定系统可以下载哪些版本
#
# 使用方法:
#   ./list-available-versions.sh ubuntu 22.04 amd64
#   ./list-available-versions.sh centos 8 x86_64
#

set -euo pipefail

# 参数
OS_TYPE="${1:-ubuntu}"
OS_VERSION="${2:-22.04}"
ARCH="${3:-amd64}"

echo "=== 查询Docker可用版本 ==="
echo "系统: $OS_TYPE $OS_VERSION"
echo "架构: $ARCH"
echo ""

if [[ "$OS_TYPE" == "ubuntu" ]]; then
    # Ubuntu代号映射
    case "$OS_VERSION" in
        20.04) CODENAME="focal" ;;
        22.04) CODENAME="jammy" ;;
        24.04) CODENAME="noble" ;;
        *) CODENAME="jammy" ;;
    esac
    
    BASE_URL="https://download.docker.com/linux/ubuntu/dists/${CODENAME}/pool/stable/${ARCH}/"
    
    echo "正在查询Ubuntu仓库..."
    echo "URL: $BASE_URL"
    echo ""
    
    # 使用curl获取目录列表
    if command -v curl >/dev/null 2>&1; then
        echo "docker-ce 可用版本:"
        curl -fsSL "$BASE_URL" | grep -oE 'docker-ce_[0-9]+\.[0-9]+\.[0-9]+-1~ubuntu[^"]*\.deb' | sort -V | tail -10
        echo ""
        
        echo "docker-compose-plugin 可用版本:"
        curl -fsSL "$BASE_URL" | grep -oE 'docker-compose-plugin_[0-9]+\.[0-9]+\.[0-9]+-1~ubuntu[^"]*\.deb' | sort -V | tail -10
        echo ""
        
        echo "containerd.io 可用版本:"
        curl -fsSL "$BASE_URL" | grep -oE 'containerd\.io_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+_[^"]*\.deb' | sort -V | tail -10
        echo ""
    else
        echo "错误: 需要curl命令"
        exit 1
    fi
    
elif [[ "$OS_TYPE" == "centos" ]]; then
    # CentOS版本映射
    CENTOS_VER="$OS_VERSION"
    if [[ "$OS_VERSION" == "stream" ]]; then
        CENTOS_VER="9"
    fi
    
    BASE_URL="https://download.docker.com/linux/centos/${CENTOS_VER}/${ARCH}/stable/Packages/"
    
    echo "正在查询CentOS仓库..."
    echo "URL: $BASE_URL"
    echo ""
    
    if command -v curl >/dev/null 2>&1; then
        echo "docker-ce 可用版本(最新10个):"
        curl -fsSL "$BASE_URL" | grep -oE 'docker-ce-[0-9]+\.[0-9]+\.[0-9]+-[^"]*\.rpm' | grep -v "cli" | grep -v "rootless" | sort -V | tail -10
        echo ""
        
        echo "docker-ce-cli 可用版本(最新10个):"
        curl -fsSL "$BASE_URL" | grep -oE 'docker-ce-cli-[0-9]+\.[0-9]+\.[0-9]+-[^"]*\.rpm' | sort -V | tail -10
        echo ""
        
        echo "containerd.io 可用版本(最新10个):"
        curl -fsSL "$BASE_URL" | grep -oE 'containerd\.io-[0-9]+\.[0-9]+\.[0-9]+-[^"]*\.rpm' | sort -V | tail -10
        echo ""
        
        echo "docker-buildx-plugin 可用版本(最新10个):"
        curl -fsSL "$BASE_URL" | grep -oE 'docker-buildx-plugin-[0-9]+\.[0-9]+\.[0-9]+-[^"]*\.rpm' | sort -V | tail -10
        echo ""
        
        echo "docker-compose-plugin 可用版本(最新10个):"
        curl -fsSL "$BASE_URL" | grep -oE 'docker-compose-plugin-[0-9]+\.[0-9]+\.[0-9]+-[^"]*\.rpm' | sort -V | tail -10
        echo ""
    else
        echo "错误: 需要curl命令"
        exit 1
    fi
else
    echo "错误: 不支持的系统类型: $OS_TYPE"
    exit 1
fi

echo "提示:"
echo "  - 可以在浏览器中访问上述URL查看完整列表"
echo "  - 下载脚本会尝试下载指定版本,如果不存在会失败"
echo "  - 建议使用 --download-mode static 下载静态二进制,更加通用"

