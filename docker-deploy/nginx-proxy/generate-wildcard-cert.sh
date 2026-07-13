#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# 可修改配置
# ============================================================

# 基础测试域名。
# 最终签发：
#   test.ingot.internal
#   *.test.ingot.internal
BASE_DOMAIN="${BASE_DOMAIN:-test.ingot.internal}"

# nginx-proxy 中使用的证书名称。
# 对应业务容器：
#   CERT_NAME=test-wildcard
CERT_NAME="${CERT_NAME:-test-wildcard}"

# nginx-proxy 证书目录。
CERT_DIR="${CERT_DIR:-/data/nginx-proxy/certs}"

# 根 CA 导出目录。
CA_EXPORT_DIR="${CA_EXPORT_DIR:-/data/nginx-proxy/ca}"

# 根 CA 导出文件名称，不包含扩展名。
# 最终生成：
#   /data/nginx-proxy/ca/ingot-test-root-ca.pem
ROOT_CA_NAME="${ROOT_CA_NAME:-ingot-test-root-ca}"

# ============================================================
# 基础检查
# ============================================================

if !command -v mkcert >/dev/null 2>&1; then
  echo "错误：未找到 mkcert，请先安装 mkcert。"
  exit 1
fi

mkdir -p "${CERT_DIR}"
mkdir -p "${CA_EXPORT_DIR}"

CERT_FILE="${CERT_DIR}/${CERT_NAME}.crt"
KEY_FILE="${CERT_DIR}/${CERT_NAME}.key"
ROOT_CA_EXPORT_FILE="${CA_EXPORT_DIR}/${ROOT_CA_NAME}.pem"

echo "基础域名：${BASE_DOMAIN}"
echo "泛域名：*.${BASE_DOMAIN}"
echo "证书文件：${CERT_FILE}"
echo "私钥文件：${KEY_FILE}"
echo "根 CA 导出文件：${ROOT_CA_EXPORT_FILE}"

# ============================================================
# 初始化 mkcert 本地 CA
# ============================================================

# 首次执行会创建本地 CA，并尝试加入服务器信任库。
mkcert -install

CAROOT="$(mkcert -CAROOT)"
MKCERT_ROOT_CA_FILE="${CAROOT}/rootCA.pem"
MKCERT_ROOT_CA_KEY_FILE="${CAROOT}/rootCA-key.pem"

if [[ ! -f "${MKCERT_ROOT_CA_FILE}" ]]; then
  echo "错误：未找到 mkcert 根 CA：${MKCERT_ROOT_CA_FILE}"
  exit 1
fi

# ============================================================
# 备份旧文件
# ============================================================

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

backup_file() {
  local file="$1"

  if [[ -f "${file}" ]]; then
    cp "${file}" "${file}.${TIMESTAMP}.bak"
    echo "已备份：${file}.${TIMESTAMP}.bak"
  fi
}

backup_file "${CERT_FILE}"
backup_file "${KEY_FILE}"
backup_file "${ROOT_CA_EXPORT_FILE}"

# ============================================================
# 生成基础域名和泛域名证书
# ============================================================

mkcert \
  -cert-file "${CERT_FILE}" \
  -key-file "${KEY_FILE}" \
  "${BASE_DOMAIN}" \
  "*.${BASE_DOMAIN}"

chmod 644 "${CERT_FILE}"
chmod 600 "${KEY_FILE}"

# ============================================================
# 导出根 CA 公钥证书
# ============================================================

cp "${MKCERT_ROOT_CA_FILE}" "${ROOT_CA_EXPORT_FILE}"
chmod 644 "${ROOT_CA_EXPORT_FILE}"

# 加固根 CA 私钥权限。
# 根 CA 私钥严禁复制或分发。
if [[ -f "${MKCERT_ROOT_CA_KEY_FILE}" ]]; then
  chmod 600 "${MKCERT_ROOT_CA_KEY_FILE}"
fi

# ============================================================
# 验证证书
# ============================================================

echo
echo "证书 SAN 信息："

openssl x509 \
  -in "${CERT_FILE}" \
  -noout \
  -ext subjectAltName

# ============================================================
# 输出结果
# ============================================================

echo
echo "证书生成完成："
echo "  业务证书：${CERT_FILE}"
echo "  业务私钥：${KEY_FILE}"
echo "  客户端根证书：${ROOT_CA_EXPORT_FILE}"
echo
echo "客户端只需要安装："
echo "${ROOT_CA_EXPORT_FILE}"
echo
echo "严禁复制或分发："
echo "${MKCERT_ROOT_CA_KEY_FILE}"
echo
echo "业务容器请配置："
echo "  CERT_NAME=${CERT_NAME}"