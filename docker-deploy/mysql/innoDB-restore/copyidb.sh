#!/bin/bash

# 配置参数
BACKUP_DIR="包含需要恢复.ibd文件的目录"  # 备份目录，包含 .ibd 文件
MYSQL_DATA_DIR="当前数据库需要恢复数据的目录，也就是需要接受.ibd文件的目录"  # MySQL 数据目录（主机路径，需与 Docker 挂载路径一致）
DOCKER_CONTAINER="docker容器名称"  # Docker 容器名称或 ID
MYSQL_USER="root"  # MySQL 用户名
MYSQL_PASSWORD="123456"  # MySQL 密码
DATABASE_NAME="admin"  # 目标数据库名

# 检查备份目录是否存在
if [ ! -d "$BACKUP_DIR" ]; then
  echo "错误：备份目录 $BACKUP_DIR 不存在！"
  exit 1
fi

# 检查 MySQL 数据目录是否存在
if [ ! -d "$MYSQL_DATA_DIR" ]; then
  echo "错误：MySQL 数据目录 $MYSQL_DATA_DIR 不存在！"
  exit 1
fi

# 检查 Docker 容器是否运行
if ! docker ps --format '{{.Names}}' | grep -q "$DOCKER_CONTAINER"; then
  echo "错误：Docker 容器 $DOCKER_CONTAINER 未运行！"
  exit 1
fi

# 遍历备份目录中的 .ibd 文件
for ibd_file in "$BACKUP_DIR"/*.ibd; do
  # 提取表名（去掉路径和 .ibd 扩展名）
  table_name=$(basename "$ibd_file" .ibd)
  echo "正在处理表：$table_name"

  # 步骤 1：执行 DISCARD TABLESPACE
  echo "  执行 DISCARD TABLESPACE..."
  docker exec "$DOCKER_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e \
    "USE $DATABASE_NAME; ALTER TABLE \`$table_name\` DISCARD TABLESPACE;" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "  错误：无法为表 $table_name 执行 DISCARD TABLESPACE"
    continue
  fi

  # 步骤 2：复制 .ibd 文件到 MySQL 数据目录
  echo "  复制 $ibd_file 到 $MYSQL_DATA_DIR..."
  cp "$ibd_file" "$MYSQL_DATA_DIR/$table_name.ibd"
  if [ $? -ne 0 ]; then
    echo "  错误：无法复制 $ibd_file"
    continue
  fi

  # 步骤 3：执行 IMPORT TABLESPACE
  echo "  执行 IMPORT TABLESPACE..."
  docker exec "$DOCKER_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e \
    "USE $DATABASE_NAME; ALTER TABLE \`$table_name\` IMPORT TABLESPACE;" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "  错误：无法为表 $table_name 执行 IMPORT TABLESPACE"
    continue
  fi

  echo "表 $table_name 处理完成！"
done

echo "所有表处理完成！"

# 可选：验证表完整性
echo "开始验证表完整性..."
docker exec "$DOCKER_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e \
  "USE $DATABASE_NAME; SHOW TABLES;" | while read -r table; do
    if [ -n "$table" ]; then
      docker exec "$DOCKER_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e \
        "CHECK TABLE \`$table\`;" 2>/dev/null
    fi
  done

echo "验证完成！建议使用 mysqldump 备份数据库。"