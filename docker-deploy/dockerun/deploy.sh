#!/usr/bin/env bash
# Dockerun 单容器部署与管理；配置见 deploy.env.example。
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="${CONFIG_FILE:-$script_dir/deploy.env}"

info() { printf '[信息] %s\n' "$*"; }
fail() { printf '[错误] %s\n' "$*" >&2; exit 1; }

show_help() {
  cat <<'HELP'
Dockerun 部署与管理

用法：./deploy.sh [命令]
  start             启动容器（默认）；已有容器沿用其原配置
  update            按当前配置重建容器，保留停止的旧容器
  check             检查配置、本地镜像、网络和 Docker socket
  pull              显式拉取配置的镜像
  stop              停止容器
  restart           重启已有容器；修改配置后请使用 update
  status            查看容器状态
  logs              持续查看日志
  shell|exec        进入容器
  remove|rm         停止并删除容器，保留持久化数据
  remove-image|rmi  删除配置的镜像，不自动删除容器
  help|-h|--help    显示帮助

默认读取脚本旁的 deploy.env；使用 CONFIG_FILE 指定其他文件。
已导出的同名环境变量优先于文件，包括显式设置的空值。
首次使用：cp deploy.env.example deploy.env，然后编辑配置。
HELP
}

is_config_key() {
  case "$1" in
    CONTAINER_NAME|IMAGE_NAME|DOCKER_NETWORK|ADDITIONAL_NETWORKS|DATA_DIR|DOCKER_SOCKET|HOST_BIND_IP|HOST_PORT|PUBLIC_URL|DATABASE_TYPE|MYSQL_DSN|VIRTUAL_HOST|LETSENCRYPT_HOST|LETSENCRYPT_EMAIL|RESTART_POLICY|PULL_POLICY|STARTUP_TIMEOUT|STOP_TIMEOUT|LOG_TAIL|JWT_SECRET|REGISTRY_SECRET|REGISTRY_HTTP_SECRET|CREDENTIALS_SECRET|AES_KEY|AES_IV) return 0 ;;
    *) return 1 ;;
  esac
}

# 仅解析单行字面量，不执行 source、命令替换或变量插值。
load_config() {
  [[ -f "$config_file" ]] || fail "配置文件不存在：$config_file；请先复制 deploy.env.example。"
  local line key value first last seen=' ' number=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    number=$((number + 1))
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$ ]] || fail "配置第 $number 行格式错误，请使用 KEY=value。"
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    is_config_key "$key" || fail "配置第 $number 行包含未知变量：$key。"
    [[ "$seen" != *" $key "* ]] || fail "配置变量重复：$key。"
    seen="$seen$key "
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    first="${value:0:1}"
    if [[ "$first" == "'" || "$first" == '"' ]]; then
      last="${value: -1}"
      [[ ${#value} -ge 2 && "$last" == "$first" ]] || fail "配置第 $number 行的引号未闭合。"
      value="${value:1:${#value}-2}"
    fi
    if ! declare -p "$key" >/dev/null 2>&1; then
      printf -v "$key" '%s' "$value"
      export "$key"
    fi
  done < "$config_file"

  local version=2.0.0
  if [[ -f "$script_dir/VERSION" ]]; then
    version="$(cat "$script_dir/VERSION")"
  fi
  CONTAINER_NAME="${CONTAINER_NAME:-dockerun}"
  IMAGE_NAME="${IMAGE_NAME:-dockerun:$version}"
  DOCKER_NETWORK="${DOCKER_NETWORK:-ingot-net}"
  ADDITIONAL_NETWORKS="${ADDITIONAL_NETWORKS:-}"
  DATA_DIR="${DATA_DIR:-/var/lib/dockerun}"
  DOCKER_SOCKET="${DOCKER_SOCKET:-/var/run/docker.sock}"
  HOST_BIND_IP="${HOST_BIND_IP:-127.0.0.1}"
  HOST_PORT="${HOST_PORT-}"
  PUBLIC_URL="${PUBLIC_URL:-}"
  DATABASE_TYPE="${DATABASE_TYPE:-mysql}"
  MYSQL_DSN="${MYSQL_DSN:-}"
  VIRTUAL_HOST="${VIRTUAL_HOST-}"
  LETSENCRYPT_HOST="${LETSENCRYPT_HOST-}"
  LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
  RESTART_POLICY="${RESTART_POLICY:-unless-stopped}"
  PULL_POLICY="${PULL_POLICY:-never}"
  STARTUP_TIMEOUT="${STARTUP_TIMEOUT:-600}"
  STOP_TIMEOUT="${STOP_TIMEOUT:-30}"
  LOG_TAIL="${LOG_TAIL:-100}"
  [[ "$CONTAINER_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]] || fail '容器名称格式错误。'
  local key_to_check
  for key_to_check in STARTUP_TIMEOUT STOP_TIMEOUT LOG_TAIL; do
    [[ "${!key_to_check}" =~ ^[1-9][0-9]{0,5}$ ]] || fail "$key_to_check 必须是大于零、最多六位的整数。"
  done
}

check_docker() {
  command -v docker >/dev/null 2>&1 || fail '未安装 Docker。'
  docker info >/dev/null 2>&1 || fail '无法连接 Docker，请检查服务状态与当前用户权限。'
}

container_exists() { docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; }
container_running() { [[ "$(docker container inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" == true ]]; }

validate_deployment() {
  DATA_DIR="${DATA_DIR%/}"
  [[ "$DATA_DIR" == /* && "$DATA_DIR" != / && "$DATA_DIR" != *:* && "$DATA_DIR" != *,* ]] || fail 'DATA_DIR 必须是非根目录的绝对路径，不能包含冒号或逗号。'
  case "$DATA_DIR/" in *'/../'*|*'/./'*|*'//'*) fail 'DATA_DIR 请使用不含 .、.. 或重复斜杠的绝对路径。' ;; esac
  [[ "$DOCKER_SOCKET" == /* && -S "$DOCKER_SOCKET" ]] || fail 'DOCKER_SOCKET 必须指向部署主机上的 Docker socket。'
  [[ "$PUBLIC_URL" =~ ^https?://[^/@?#[:space:]]+/?$ ]] || fail 'PUBLIC_URL 必须是完整的 http(s) 根地址，不含路径或凭据。'
  case "$DATABASE_TYPE" in
    mysql) [[ -n "$MYSQL_DSN" ]] || fail 'MySQL 模式必须设置 MYSQL_DSN。' ;;
    sqlite) ;;
    *) fail 'DATABASE_TYPE 仅支持 mysql 或 sqlite。' ;;
  esac
  case "$PULL_POLICY" in never|missing|always) ;; *) fail 'PULL_POLICY 仅支持 never、missing 或 always。' ;; esac
  [[ "$RESTART_POLICY" =~ ^(no|always|unless-stopped|on-failure(:[1-9][0-9]*)?)$ ]] || fail 'RESTART_POLICY 格式错误。'
  if [[ -n "$HOST_PORT" ]]; then
    [[ "$HOST_PORT" =~ ^[1-9][0-9]{0,4}$ ]] && (( HOST_PORT <= 65535 )) || fail 'HOST_PORT 必须是 1 至 65535，留空则不映射宿主端口。'
    [[ "$HOST_BIND_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || fail 'HOST_BIND_IP 必须是 IPv4 地址。'
    local part
    local ip_parts
    IFS='.' read -r -a ip_parts <<< "$HOST_BIND_IP"
    for part in "${ip_parts[@]}"; do
      (( 10#$part <= 255 )) || fail 'HOST_BIND_IP 的地址段必须是 0 至 255。'
    done
  fi
  if [[ -n "$VIRTUAL_HOST" ]]; then
    [[ "$VIRTUAL_HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || fail 'VIRTUAL_HOST 只支持一个不带端口的域名。'
    [[ "${PUBLIC_URL%/}" == "https://$VIRTUAL_HOST" || "${PUBLIC_URL%/}" == "http://$VIRTUAL_HOST" ]] || fail '代理模式下 PUBLIC_URL 必须与 VIRTUAL_HOST 的域名一致。'
    [[ -z "$LETSENCRYPT_HOST" || "$LETSENCRYPT_HOST" == "$VIRTUAL_HOST" ]] || fail 'LETSENCRYPT_HOST 必须与 VIRTUAL_HOST 一致，或留空使用已有证书。'
    [[ -z "$LETSENCRYPT_HOST" || "$PUBLIC_URL" == https://* ]] || fail '启用自动证书时 PUBLIC_URL 必须使用 https。'
  else
    [[ -z "$LETSENCRYPT_HOST" ]] || fail '设置 LETSENCRYPT_HOST 前必须设置 VIRTUAL_HOST。'
    [[ -n "$HOST_PORT" ]] || fail '未启用 nginx-proxy 时必须设置 HOST_PORT。'
  fi
  local network
  local networks=("$DOCKER_NETWORK")
  if [[ -n "$ADDITIONAL_NETWORKS" ]]; then
    local extra_networks
    read -r -a extra_networks <<< "$ADDITIONAL_NETWORKS"
    networks+=("${extra_networks[@]}")
  fi
  for network in "${networks[@]}"; do
    docker network inspect "$network" >/dev/null 2>&1 || fail "Docker 网络不存在：$network；请使用现有代理或数据库网络。"
  done
}

check_image_platform() {
  local image_platform server_platform
  image_platform="$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$IMAGE_NAME")" || fail '无法读取镜像平台。'
  server_platform="$(docker version --format '{{.Server.Os}}/{{.Server.Arch}}')" || fail '无法读取 Docker 服务平台。'
  [[ "$image_platform" == "$server_platform" ]] || fail "镜像平台 $image_platform 与目标 Docker 平台 $server_platform 不一致，请加载匹配架构的镜像包。"
}

prepare_image() {
  if [[ "$PULL_POLICY" == always ]]; then
    docker pull "$IMAGE_NAME" >/dev/null || fail '镜像拉取失败，原容器未修改。'
  elif ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    [[ "$PULL_POLICY" == missing ]] || fail "本地镜像不存在：$IMAGE_NAME；请先构建、docker load 或显式执行 pull。"
    docker pull "$IMAGE_NAME" >/dev/null || fail '镜像拉取失败，原容器未修改。'
  fi
  docker image inspect "$IMAGE_NAME" >/dev/null 2>&1 || fail '无法读取目标镜像。'
  check_image_platform
}

create_candidate() {
  local candidate="$1" key network
  mkdir -p -m 700 "$DATA_DIR" || fail '无法创建数据目录，请检查权限。'
  local args=(create --name "$candidate" --network "$DOCKER_NETWORK" --restart "$RESTART_POLICY"
    --label io.dockerun.deployment=script --expose 8080
    --mount "type=bind,src=$DOCKER_SOCKET,dst=/var/run/docker.sock"
    --mount "type=bind,src=$DATA_DIR,dst=$DATA_DIR"
    --health-cmd 'curl --fail --silent --max-time 5 http://127.0.0.1:8080/health || exit 1'
    --health-interval 5s --health-timeout 6s --health-start-period "${STARTUP_TIMEOUT}s" --health-retries 3)
  if [[ -n "$HOST_PORT" ]]; then
    args+=(--publish "$HOST_BIND_IP:$HOST_PORT:8080")
  fi
  export PUBLIC_URL DATA_DIR DATABASE_TYPE MYSQL_DSN
  export VIRTUAL_HOST LETSENCRYPT_HOST LETSENCRYPT_EMAIL
  for key in PUBLIC_URL DATA_DIR DATABASE_TYPE MYSQL_DSN; do
    args+=(--env "$key")
  done
  if [[ -n "$VIRTUAL_HOST" ]]; then
    args+=(--env VIRTUAL_HOST --env VIRTUAL_PORT=8080 --env LETSENCRYPT_HOST --env LETSENCRYPT_EMAIL)
  fi
  for key in JWT_SECRET REGISTRY_SECRET REGISTRY_HTTP_SECRET CREDENTIALS_SECRET AES_KEY AES_IV; do
    if [[ -n "${!key:-}" ]]; then
      export "$key"
      args+=(--env "$key")
    fi
  done
  docker "${args[@]}" "$IMAGE_NAME" >/dev/null || fail '创建新容器失败，原容器未修改。'
  if [[ -n "$ADDITIONAL_NETWORKS" ]]; then
    local extra_networks
    read -r -a extra_networks <<< "$ADDITIONAL_NETWORKS"
    for network in "${extra_networks[@]}"; do
      [[ "$network" == "$DOCKER_NETWORK" ]] && continue
      if ! docker network connect "$network" "$candidate"; then
        docker rm "$candidate" >/dev/null || true
        fail '新容器连接附加网络失败，原容器未修改。'
      fi
    done
  fi
}

wait_healthy() {
  local deadline=$((SECONDS + STARTUP_TIMEOUT)) state
  while (( SECONDS < deadline )); do
    state="$(docker container inspect --format '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER_NAME")" || return 1
    case "$state" in
      'running healthy') info "服务健康检查通过；访问入口：$PUBLIC_URL"; return 0 ;;
      'running starting'|'created none'|'restarting '*|'running none') ;;
      *) printf '[错误] 容器未就绪：%s\n' "$state" >&2; return 1 ;;
    esac
    sleep 2
  done
  printf '[错误] 等待健康检查超时（%s 秒）。\n' "$STARTUP_TIMEOUT" >&2
  return 1
}

deploy_container() {
  validate_deployment
  prepare_image
  local suffix="$(date +%Y%m%d%H%M%S)-$$"
  local candidate="$CONTAINER_NAME-pending-$suffix" previous=''
  create_candidate "$candidate"
  if container_exists; then
    previous="$CONTAINER_NAME-previous-$suffix"
    if ! docker stop --time "$STOP_TIMEOUT" "$CONTAINER_NAME" >/dev/null; then
      docker rm "$candidate" >/dev/null || true
      fail '停止原容器失败，新容器尚未启动。'
    fi
    if ! docker rename "$CONTAINER_NAME" "$previous"; then
      docker rm "$candidate" >/dev/null || true
      fail '保留原容器失败；原容器可能已停止，请检查状态。'
    fi
    info "原容器已停止并保留为：$previous"
  fi
  docker rename "$candidate" "$CONTAINER_NAME" || fail "新容器重命名失败，待处理容器：$candidate；原容器：${previous:-无}。"
  if ! docker start "$CONTAINER_NAME" >/dev/null || ! wait_healthy; then
    printf '[错误] 部署未完成；请使用 logs 查看原因。旧容器：%s。\n' "${previous:-无}" >&2
    fail '新版本可能已迁移数据库，未自动启动旧版本；恢复前请核对数据库与文件备份。'
  fi
  info '网页与内置仓库共用 PUBLIC_URL；还需从客户端验证 docker login。'
}

show_status() {
  if container_exists; then
    docker container inspect --format '容器：{{.Name}}　镜像：{{.Config.Image}}　状态：{{.State.Status}}　健康：{{if .State.Health}}{{.State.Health.Status}}{{else}}未配置{{end}}' "$CONTAINER_NAME"
    docker port "$CONTAINER_NAME"
  else
    info "容器不存在：$CONTAINER_NAME"
  fi
}

main() {
  local action="${1:-start}"
  [[ $# -le 1 ]] || fail '只接受一个命令；配置文件通过 CONFIG_FILE 指定。'
  case "$action" in
    help|-h|--help) show_help; return ;;
    start|update|check|pull|stop|restart|status|logs|shell|exec|remove|rm|remove-image|rmi) ;;
    *) fail "未知命令：$action；使用 help 查看帮助。" ;;
  esac
  load_config
  check_docker
  case "$action" in
    check)
      validate_deployment
      docker image inspect "$IMAGE_NAME" >/dev/null 2>&1 || fail '本地镜像不存在；check 不会拉取镜像。'
      check_image_platform
      info '配置、本地镜像与平台、网络及 Docker socket 检查通过；未启动容器或修改数据库。'
      ;;
    pull) docker pull "$IMAGE_NAME" ;;
    start)
      if container_exists; then
        if ! container_running; then
          docker start "$CONTAINER_NAME" >/dev/null
          wait_healthy || fail '已有容器未就绪，请查看日志。'
        fi
        info '已有容器沿用其创建时的配置；应用当前镜像与配置请执行 update。'
        show_status
      else
        deploy_container
      fi
      ;;
    update) deploy_container ;;
    stop)
      if container_exists; then docker stop --time "$STOP_TIMEOUT" "$CONTAINER_NAME"; else info '容器不存在。'; fi
      ;;
    restart)
      if container_exists; then
        docker restart --time "$STOP_TIMEOUT" "$CONTAINER_NAME" >/dev/null
        wait_healthy || fail '容器重启后未就绪，请查看日志。'
        info '重启保留原配置；应用配置变更请执行 update。'
      else
        deploy_container
      fi
      ;;
    status) show_status ;;
    logs) docker logs --follow --tail "$LOG_TAIL" "$CONTAINER_NAME" ;;
    shell|exec) docker exec -it "$CONTAINER_NAME" /bin/sh ;;
    remove|rm)
      if container_exists; then
        docker stop --time "$STOP_TIMEOUT" "$CONTAINER_NAME" >/dev/null
        docker rm "$CONTAINER_NAME"
        info '容器已删除，持久化目录与 MySQL 数据保留。'
      else
        info '容器不存在。'
      fi
      ;;
    remove-image|rmi) docker image rm "$IMAGE_NAME" ;;
  esac
}

main "$@"
