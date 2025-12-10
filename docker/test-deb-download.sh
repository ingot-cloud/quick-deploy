#!/usr/bin/env bash
#
# test-deb-download.sh - 测试DEB包下载修复
# 验证Ubuntu DEB包URL是否正确
#

set -euo pipefail

echo "=== 测试DEB包URL构建 ==="
echo ""

# 测试参数
DOCKER_VERSION="27.4.1"
OS_VERSION="22.04"
CODENAME="jammy"
DEB_ARCH="amd64"

echo "配置:"
echo "  Docker版本: $DOCKER_VERSION"
echo "  Ubuntu版本: $OS_VERSION ($CODENAME)"
echo "  架构: $DEB_ARCH"
echo ""

# 构建URL
BASE_URL="https://download.docker.com/linux/ubuntu/dists/${CODENAME}/pool/stable/${DEB_ARCH}"

# 测试各个包的URL
echo "测试URL可访问性..."
echo ""

packages=(
    "docker-ce_${DOCKER_VERSION}-1~ubuntu.${OS_VERSION}~${CODENAME}_${DEB_ARCH}.deb"
    "docker-ce-cli_${DOCKER_VERSION}-1~ubuntu.${OS_VERSION}~${CODENAME}_${DEB_ARCH}.deb"
)

for pkg in "${packages[@]}"; do
    url="${BASE_URL}/${pkg}"
    echo -n "检查: $pkg ... "
    
    if curl -fsSL -I "$url" >/dev/null 2>&1; then
        echo "✅ 可访问"
    else
        echo "❌ 不可访问"
        echo "  URL: $url"
    fi
done

echo ""
echo "提示:"
echo "  - 如果包不可访问,可能是版本号已更新"
echo "  - 使用 ./list-available-versions.sh ubuntu 22.04 amd64 查看可用版本"
echo "  - 或使用 --download-mode static 下载静态二进制"

