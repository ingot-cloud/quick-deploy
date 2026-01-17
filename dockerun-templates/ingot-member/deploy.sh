#!/usr/bin/env bash

set -e

echo "========================================"
echo "  Docker 容器部署脚本"
echo "========================================"

# 切换到工作目录
cd "${WORK_DIR:-.}"

echo ""
echo "工作目录: $(pwd)"
echo ""

# 使用 docker-manager.sh 启动容器
# 用法: bash docker-manager.sh <配置文件.env> <命令>
bash docker-manager.sh app.env start

echo ""
echo "========================================"
echo "  部署完成！"
echo "========================================"
echo ""
echo "常用命令:"
echo "  查看状态: bash docker-manager.sh app.env status"
echo "  查看日志: bash docker-manager.sh app.env logs -f"
echo "  停止容器: bash docker-manager.sh app.env stop"
echo "  重启容器: bash docker-manager.sh app.env restart"
echo "  进入容器: bash docker-manager.sh app.env exec"
echo "  删除容器: bash docker-manager.sh app.env rm"
echo "  删除容器和镜像: bash docker-manager.sh app.env rmi"
echo ""
