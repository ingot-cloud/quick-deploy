#!/usr/bin/env bash

# 拉取镜像并且推送到私有仓库,保持多架构
# 使用方法: ./pullimage2privateregistry.sh [IMAGE] [TAG]
# 示例: ./pullimage2privateregistry.sh amazoncorretto 17

set -e  # 遇到错误立即退出

# ==================== 配置区 ====================
IMAGE=${1:-amazoncorretto}
TAG=${2:-17}
PRIVATE_REGISTRY=docker-registry.ingotcloud.top
ARCHITECTURES=("amd64" "arm64")
CLEAN_LOCAL=false  # 是否清理本地临时镜像

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==================== 主要逻辑 ====================
log_info "开始处理镜像: $IMAGE:$TAG"
log_info "目标仓库: $PRIVATE_REGISTRY"
log_info "支持架构: ${ARCHITECTURES[*]}"
echo ""

# 1. 拉取并推送各架构镜像
for ARCH in "${ARCHITECTURES[@]}"; do
    log_info "[$ARCH] 开始拉取镜像..."
    
    # 拉取指定架构的镜像
    if docker pull --platform linux/$ARCH $IMAGE:$TAG; then
        log_info "[$ARCH] 拉取成功"
    else
        log_error "[$ARCH] 拉取失败，跳过此架构"
        continue
    fi
    
    # 直接标记为目标架构标签
    TARGET_IMAGE="$PRIVATE_REGISTRY/$IMAGE:$TAG-$ARCH"
    log_info "[$ARCH] 标记镜像为: $TARGET_IMAGE"
    docker tag $IMAGE:$TAG $TARGET_IMAGE
    
    # 推送到私有仓库
    log_info "[$ARCH] 推送镜像到私有仓库..."
    if docker push $TARGET_IMAGE; then
        log_info "[$ARCH] 推送成功"
    else
        log_error "[$ARCH] 推送失败"
        exit 1
    fi
    
    echo ""
done

# 2. 清理可能存在的旧 manifest
log_info "清理可能存在的旧 manifest..."
docker manifest rm $PRIVATE_REGISTRY/$IMAGE:$TAG 2>/dev/null || true

# 3. 创建多架构 Manifest
log_info "创建多架构 manifest..."
MANIFEST_CMD="docker manifest create $PRIVATE_REGISTRY/$IMAGE:$TAG"
for ARCH in "${ARCHITECTURES[@]}"; do
    MANIFEST_CMD="$MANIFEST_CMD --amend $PRIVATE_REGISTRY/$IMAGE:$TAG-$ARCH"
done

if eval $MANIFEST_CMD; then
    log_info "Manifest 创建成功"
else
    log_error "Manifest 创建失败"
    exit 1
fi

# 4. 推送 Manifest
log_info "推送多架构 manifest..."
if docker manifest push $PRIVATE_REGISTRY/$IMAGE:$TAG; then
    log_info "Manifest 推送成功"
else
    log_error "Manifest 推送失败"
    exit 1
fi

echo ""
log_info "✅ 多架构镜像处理完成！"
log_info "镜像地址: $PRIVATE_REGISTRY/$IMAGE:$TAG"

# 5. 清理本地临时镜像（可选）
if [ "$CLEAN_LOCAL" = true ]; then
    log_info "清理本地临时镜像..."
    for ARCH in "${ARCHITECTURES[@]}"; do
        docker rmi $PRIVATE_REGISTRY/$IMAGE:$TAG-$ARCH 2>/dev/null || true
    done
    docker rmi $IMAGE:$TAG 2>/dev/null || true
    log_info "清理完成"
fi

echo ""
log_info "验证命令: docker manifest inspect $PRIVATE_REGISTRY/$IMAGE:$TAG"