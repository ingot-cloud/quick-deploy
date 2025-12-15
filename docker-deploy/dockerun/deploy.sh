#!/usr/bin/env bash

###############################################################################
# Dockerun Quick Run Script
# 用途：快速启动或停止 Dockerun 容器
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
CONTAINER_NAME="dockerun"
IMAGE_NAME="docker-registry.ingotcloud.top/ingot/dockerun:0.1.0"
HOST_PORT="19000"
# TEMPLATES_VOLUME="/ingot-data/dockerun/templates"  # 模板现在内置在镜像中

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker 守护进程未运行"
        exit 1
    fi
}

# 检查镜像是否存在
check_image() {
    if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
        log_error "镜像 ${IMAGE_NAME} 不存在"
        docker pull "${IMAGE_NAME}"
        if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
            log_error "镜像 ${IMAGE_NAME} 拉取失败"
            exit 1
        fi
    fi
}

# 启动容器
start_container() {
    log_info "启动 Dockerun 容器..."
    
    # 检查容器是否已存在
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        # 容器存在，检查是否运行
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            log_warning "容器已在运行中"
            show_status
            return
        else
            # 容器存在但未运行，启动它
            log_info "启动已存在的容器..."
            docker start "${CONTAINER_NAME}"
        fi
    else
        # 容器不存在，创建并运行
        log_info "创建新容器..."
        docker run -d \
            --name "${CONTAINER_NAME}" \
            -p "${HOST_PORT}:8080" \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --restart unless-stopped \
            "${IMAGE_NAME}"
    fi
    
    # 等待容器启动
    sleep 2
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_success "容器启动成功！"
        echo ""
        log_info "访问地址: http://localhost:${HOST_PORT}"
        log_info "查看日志: docker logs -f ${CONTAINER_NAME}"
        echo ""
    else
        log_error "容器启动失败"
        log_info "查看日志: docker logs ${CONTAINER_NAME}"
        exit 1
    fi
}

# 停止容器
stop_container() {
    log_info "停止 Dockerun 容器..."
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker stop "${CONTAINER_NAME}"
        log_success "容器已停止"
    else
        log_warning "容器未在运行"
    fi
}

# 重启容器
restart_container() {
    log_info "重启 Dockerun 容器..."
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker restart "${CONTAINER_NAME}"
        log_success "容器已重启"
        show_status
    else
        log_warning "容器不存在，将创建新容器"
        start_container
    fi
}

# 删除容器
remove_container() {
    log_info "删除 Dockerun 容器..."
    
    # 先停止容器
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker stop "${CONTAINER_NAME}"
    fi
    
    # 删除容器
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker rm "${CONTAINER_NAME}"
        log_success "容器已删除"
    else
        log_warning "容器不存在"
    fi
}

# 删除镜像
remove_image() {
    log_info "删除 Dockerun 镜像..."
    docker rmi "${IMAGE_NAME}"
    log_success "镜像已删除"
}

# 查看日志
show_logs() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker logs -f --tail 100 "${CONTAINER_NAME}"
    else
        log_error "容器不存在"
        exit 1
    fi
}

# 查看状态
show_status() {
    echo ""
    log_info "容器状态:"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # 如果容器在运行，显示资源使用情况
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            log_info "资源使用:"
            docker stats "${CONTAINER_NAME}" --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        fi
    else
        log_warning "容器不存在"
    fi
    echo ""
}

# 进入容器
exec_shell() {
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "进入容器 shell..."
        docker exec -it "${CONTAINER_NAME}" /bin/sh
    else
        log_error "容器未运行"
        exit 1
    fi
}

# 显示帮助
show_help() {
    echo "Dockerun 快速运行脚本"
    echo ""
    echo "用法: ./run.sh [命令]"
    echo ""
    echo "命令:"
    echo "  start             启动容器（默认）"
    echo "  stop              停止容器"
    echo "  restart           重启容器"
    echo "  remove|rm         删除容器"
    echo "  remove-image|rmi  删除镜像"
    echo "  logs              查看日志"
    echo "  status            查看状态"
    echo "  shell|exec        进入容器 shell"
    echo "  help|-h|--help    显示帮助"
    echo ""
    echo "环境变量:"
    echo "  DOCKERUN_PORT    主机端口（默认: 8080）"
    echo ""
    echo "示例:"
    echo "  ./run.sh              # 启动容器"
    echo "  ./run.sh stop         # 停止容器"
    echo "  ./run.sh logs         # 查看日志"
    echo "  DOCKERUN_PORT=9000 ./run.sh start  # 使用端口 9000"
    echo ""
}

# 主函数
main() {
    check_docker
    
    case "${1:-start}" in
        start)
            check_image
            start_container
            ;;
        stop)
            stop_container
            ;;
        restart)
            check_image
            restart_container
            ;;
        remove|rm)
            remove_container
            ;;
        remove-image|rmi)
            remove_image
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        shell|exec)
            exec_shell
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"

