#!/usr/bin/env bash
#
# test-download.sh - 测试离线包下载功能
# 用于验证download-docker-offline.sh脚本能否正常工作
#
# 使用方法:
#   ./test-download.sh
#

set -euo pipefail

echo "=== Docker离线下载脚本测试 ==="
echo ""

# 检查下载脚本是否存在
if [[ ! -f "./download-docker-offline.sh" ]]; then
    echo "错误: 未找到 download-docker-offline.sh"
    exit 1
fi

echo "测试场景1: 下载CentOS 8 amd64离线包 (静态二进制)"
echo "----------------------------------------"
./download-docker-offline.sh \
    --docker-version 27.4.1 \
    --compose-version v2.30.3 \
    --os-type centos \
    --os-version 8 \
    --arch amd64 \
    --download-mode static \
    --non-interactive

echo ""
echo "✅ 测试场景1完成"
echo ""

# 检查生成的目录
GENERATED_DIR=$(ls -d docker-offline-* 2>/dev/null | head -1)

if [[ -n "$GENERATED_DIR" ]]; then
    echo "生成的目录: $GENERATED_DIR"
    echo ""
    echo "目录内容:"
    ls -lh "$GENERATED_DIR/" 2>/dev/null || true
    echo ""
    
    if [[ -f "$GENERATED_DIR/install.sh" ]]; then
        echo "✅ install.sh 已生成"
    else
        echo "❌ install.sh 未找到"
    fi
    
    if [[ -f "$GENERATED_DIR/metadata.json" ]]; then
        echo "✅ metadata.json 已生成"
        echo ""
        echo "元数据内容:"
        cat "$GENERATED_DIR/metadata.json" 2>/dev/null || true
    else
        echo "❌ metadata.json 未找到"
    fi
    
    if [[ -d "$GENERATED_DIR/static" ]]; then
        echo "✅ static目录已创建"
        echo ""
        echo "静态文件:"
        ls -lh "$GENERATED_DIR/static/" 2>/dev/null || true
    fi
    
    echo ""
    echo "=== 测试完成 ==="
    echo ""
    echo "提示: 可以手动清理测试目录"
    echo "  rm -rf $GENERATED_DIR"
else
    echo "❌ 未找到生成的离线包目录"
    exit 1
fi

