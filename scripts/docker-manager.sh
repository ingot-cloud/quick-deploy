#!/usr/bin/env bash

###############################################################################
# Docker 容器管理脚本 V2
# 基于配置文件 + 执行脚本的灵活架构
# 
# 架构说明:
#   1. 配置文件 (.env) - 定义环境变量
#   2. 执行脚本 (-run.sh) - 编写具体的 docker run 命令
#   3. 管理脚本 (本脚本) - 提供容器管理功能
#
# 用法:
#   ./docker-manager.sh <执行脚本> <命令> [选项]
#   ./docker-manager.sh myapp-run.sh start
#   ./docker-manager.sh myapp-run.sh stop
#   ./docker-manager.sh myapp-run.sh logs -f
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

###############################################################################
# 工具函数
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[→]${NC} $1"
}

print_separator() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

# 检查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        echo "请安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker 守护进程未运行"
        exit 1
    fi
}

###############################################################################
# 容器操作
###############################################################################

# 启动容器
start_container() {
    local run_script="$1"
    
    if [ ! -f "$run_script" ]; then
        log_error "执行脚本不存在: $run_script"
        exit 1
    fi
    
    log_step "执行启动脚本: $run_script"
    
    # 检查容器是否已存在
    if [ -n "$CONTAINER_NAME" ]; then
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                log_warning "容器 [$CONTAINER_NAME] 已在运行中"
                show_status
                return 0
            else
                log_info "启动已存在的容器 [$CONTAINER_NAME]..."
                docker start "$CONTAINER_NAME"
                log_success "容器启动成功"
                show_status
                return 0
            fi
        fi
    fi
    
    # 执行启动脚本
    bash "$run_script"
    
    if [ $? -eq 0 ]; then
        log_success "容器启动成功"
        echo ""
        show_status
    else
        log_error "容器启动失败"
        exit 1
    fi
}

# 停止容器
stop_container() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    log_step "停止容器: $CONTAINER_NAME"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warning "容器未运行"
        return 0
    fi
    
    docker stop "$CONTAINER_NAME"
    log_success "容器已停止"
}

# 重启容器
restart_container() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    log_step "重启容器: $CONTAINER_NAME"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker restart "$CONTAINER_NAME"
        log_success "容器已重启"
        show_status
    else
        log_error "容器不存在"
        return 1
    fi
}

# 删除容器
remove_container() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    log_step "删除容器: $CONTAINER_NAME"
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warning "容器不存在"
        return 0
    fi
    
    # 停止容器（如果正在运行）
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "停止容器..."
        docker stop "$CONTAINER_NAME"
    fi
    
    docker rm "$CONTAINER_NAME"
    log_success "容器已删除"
}

# 删除容器和镜像
remove_all() {
    if [ -z "$CONTAINER_NAME" ] || [ -z "$IMAGE_NAME" ]; then
        log_error "未定义 CONTAINER_NAME 或 IMAGE_NAME"
        exit 1
    fi
    
    # 先删除容器
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_step "删除容器: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME"
        log_success "容器已删除"
    fi
    
    # 删除镜像
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
        log_step "删除镜像: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME"
        log_success "镜像已删除"
    else
        log_warning "镜像不存在: $IMAGE_NAME"
    fi
}

# 查看状态
show_status() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    print_separator
    echo -e "${CYAN}容器状态: $CONTAINER_NAME${NC}"
    print_separator
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker ps -a --filter "name=^${CONTAINER_NAME}$" \
            --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_warning "容器不存在"
    fi
    
    print_separator
}

# 查看日志
show_logs() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    local follow="${1:-false}"
    local lines="${2:-100}"
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器不存在"
        return 1
    fi
    
    if [ "$follow" = "true" ] || [ "$follow" = "-f" ]; then
        log_info "实时查看日志（Ctrl+C 退出）..."
        docker logs -f --tail "$lines" "$CONTAINER_NAME"
    else
        docker logs --tail "$lines" "$CONTAINER_NAME"
    fi
}

# 进入容器
exec_shell() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    local shell="${1:-bash}"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器未运行"
        return 1
    fi
    
    log_info "进入容器 (shell: $shell)..."
    docker exec -it "$CONTAINER_NAME" "$shell" || \
    docker exec -it "$CONTAINER_NAME" sh
}

# 查看容器信息
inspect_container() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器不存在"
        return 1
    fi
    
    docker inspect "$CONTAINER_NAME"
}

# 查看容器资源使用
show_stats() {
    if [ -z "$CONTAINER_NAME" ]; then
        log_error "未定义 CONTAINER_NAME"
        exit 1
    fi
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器未运行"
        return 1
    fi
    
    docker stats "$CONTAINER_NAME"
}

###############################################################################
# 帮助信息
###############################################################################

show_help() {
    cat << EOF
${CYAN}Docker 容器管理脚本 V2${NC}

${YELLOW}架构说明:${NC}
  1. 配置文件 (.env) - 定义环境变量
  2. 执行脚本 (-run.sh) - 编写具体的 docker run 命令
  3. 管理脚本 (本脚本) - 提供容器管理功能

${YELLOW}用法:${NC}
  $(basename "$0") <执行脚本> <命令> [选项]

${YELLOW}命令:${NC}
  start                启动容器（执行启动脚本）
  stop                 停止容器
  restart              重启容器
  remove, rm           删除容器
  remove-all, rmi      删除容器和镜像
  status, ps           查看容器状态
  logs [lines]         查看日志（默认最后 100 行）
  logs -f [lines]      实时查看日志
  exec [shell]         进入容器（默认 bash）
  inspect              查看容器详细信息
  stats                查看容器资源使用情况
  help                 显示帮助信息

${YELLOW}示例:${NC}
  # 启动容器
  $(basename "$0") myapp-run.sh start

  # 停止容器
  $(basename "$0") myapp-run.sh stop

  # 查看日志
  $(basename "$0") myapp-run.sh logs -f

  # 进入容器
  $(basename "$0") myapp-run.sh exec

  # 查看状态
  $(basename "$0") myapp-run.sh status

${YELLOW}文件结构:${NC}
  myapp.env           # 配置文件（定义环境变量）
  myapp-run.sh        # 执行脚本（编写 docker run 命令）
  docker-manager.sh   # 管理脚本（本脚本）

${YELLOW}工作流程:${NC}
  1. 创建配置文件: cp example.env myapp.env
  2. 创建执行脚本: cp example-run.sh myapp-run.sh
  3. 编辑配置文件: vi myapp.env
  4. 编辑执行脚本: vi myapp-run.sh（根据需要添加 --ip、--add-host 等参数）
  5. 启动容器: $(basename "$0") myapp-run.sh start

${YELLOW}优势:${NC}
  ✓ 完全灵活 - 在执行脚本中可以使用任何 docker run 参数
  ✓ 易于维护 - 配置和命令分离，清晰明了
  ✓ 无需适配 - Docker 更新后无需修改管理脚本
  ✓ 复用简单 - 复制配置文件和执行脚本即可

EOF
}

###############################################################################
# 主程序
###############################################################################

main() {
    # 检查参数
    if [ $# -lt 1 ]; then
        show_help
        exit 1
    fi
    
    # 检查 Docker
    check_docker
    
    # 获取执行脚本和命令
    local run_script="$1"
    local command="${2:-help}"
    shift 2 || shift || true
    
    # 如果第一个参数是帮助命令
    if [ "$run_script" = "help" ] || [ "$run_script" = "--help" ] || [ "$run_script" = "-h" ]; then
        show_help
        exit 0
    fi
    
    # 加载执行脚本中的环境变量（如果定义了配置文件）
    if [ -f "$run_script" ]; then
        # 从执行脚本中提取配置文件路径
        local config_file
        config_file=$(grep -E "^CONFIG_FILE=" "$run_script" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        
        # 如果配置文件存在，则加载
        if [ -n "$config_file" ] && [ -f "$config_file" ]; then
            log_info "加载配置文件: $config_file"
            # shellcheck source=/dev/null
            source "$config_file"
        fi
        
        # 加载执行脚本中定义的环境变量
        # shellcheck source=/dev/null
        source "$run_script"
    fi
    
    # 执行命令
    case "$command" in
        start)
            start_container "$run_script"
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            ;;
        remove|rm)
            remove_container
            ;;
        remove-all|rmi)
            remove_all
            ;;
        status|ps)
            show_status
            ;;
        logs)
            show_logs "$@"
            ;;
        exec)
            exec_shell "$@"
            ;;
        inspect)
            inspect_container
            ;;
        stats)
            show_stats
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"

