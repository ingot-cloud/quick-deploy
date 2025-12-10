#!/usr/bin/env bash
set -euo pipefail

# offline-docker-builder.sh (FINAL, fixed)
# Usage examples:
#  interactive: ./offline-docker-builder.sh
#  non-interactive: ./offline-docker-builder.sh 28.4.0 amd64 --mode auto --os centos --os-version 8 --compose-version v5.0.0

# ----------------- Defaults -----------------
DEFAULT_DOCKER_VERSION="28.4.0"
DEFAULT_COMPOSE_V2="v5.0.0"
DEFAULT_COMPOSE_V1="1.29.2"
DEFAULT_MODE="auto"         # auto | rpm-only | deb-only | static-only
DEFAULT_OS="centos"         # centos | ubuntu
DEFAULT_CENTOS_VERSION="8"  # 7 | 8 | 9 | stream
DEFAULT_UBUNTU_RELEASE="22.04" # 20.04 | 22.04 | 24.04
DEFAULT_ARCH="amd64"        # amd64 | arm64

# ----------------- helpers -----------------
prompt_default() {
  local prompt="$1" default="$2"
  read -rp "$prompt [$default]: " val
  echo "${val:-$default}"
}

download() {
  local url="$1" out="$2"
  echo "-> Downloading: $url"
  if curl -fsSL --retry 3 --retry-delay 2 "$url" -o "$out"; then
    echo "   saved -> $out"
    return 0
  else
    echo "   FAILED -> $url"
    rm -f "$out" || true
    return 1
  fi
}

# ----------------- parse input / interactive -----------------
if [[ $# -lt 2 ]]; then
  echo "Interactive mode (press Enter to accept defaults)."
  DOCKER_VERSION=$(prompt_default "Docker version" "$DEFAULT_DOCKER_VERSION")
  ARCH=$(prompt_default "Arch (amd64|arm64)" "$DEFAULT_ARCH")
  MODE=$(prompt_default "Mode (auto|rpm-only|deb-only|static-only)" "$DEFAULT_MODE")
  OS=$(prompt_default "Target OS family (centos|ubuntu)" "$DEFAULT_OS")
  if [[ "$OS" == "centos" ]]; then
    CENTOS_VERSION=$(prompt_default "CentOS variant (7|8|9|stream)" "$DEFAULT_CENTOS_VERSION")
    UBUNTU_RELEASE="${DEFAULT_UBUNTU_RELEASE}"
  else
    UBUNTU_RELEASE=$(prompt_default "Ubuntu release (20.04|22.04|24.04)" "$DEFAULT_UBUNTU_RELEASE")
    CENTOS_VERSION="${DEFAULT_CENTOS_VERSION}"
  fi
  COMPOSE_V2=$(prompt_default "Compose v2 version" "$DEFAULT_COMPOSE_V2")
  COMPOSE_V1="$DEFAULT_COMPOSE_V1"
else
  # non-interactive minimal: <docker_version> <arch>
  DOCKER_VERSION="$1"; ARCH="$2"; shift 2
  MODE="$DEFAULT_MODE"; OS="$DEFAULT_OS"; CENTOS_VERSION="$DEFAULT_CENTOS_VERSION"; UBUNTU_RELEASE="$DEFAULT_UBUNTU_RELEASE"; COMPOSE_V2="$DEFAULT_COMPOSE_V2"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode) MODE="$2"; shift 2;;
      --os) OS="$2"; shift 2;;
      --os-version) 
        if [[ "$OS" == "centos" ]]; then CENTOS_VERSION="$2"; else UBUNTU_RELEASE="$2"; fi
        shift 2;;
      --compose-version) COMPOSE_V2="$2"; shift 2;;
      --help|-h) echo "Usage: $0 <docker_version> <arch> [--mode ...] [--os centos|ubuntu] [--os-version <ver>] [--compose-version <vX.Y.Z>]"; exit 0;;
      *) echo "Unknown arg: $1"; exit 1;;
    esac
  done
  COMPOSE_V1="$DEFAULT_COMPOSE_V1"
fi

# ----------------- normalize arch and mapping -----------------
case "$ARCH" in
  amd64|x86_64)
    ARCH_NORM="amd64"
    DOCKER_STATIC_ARCH="x86_64"   # static docker uses x86_64
    COMPOSE_ARCH_V2="x86_64"      # compose binary naming uses x86_64
    COMPOSE_ARCH_V1="x86_64"
    ;;
  arm64|aarch64)
    ARCH_NORM="arm64"
    DOCKER_STATIC_ARCH="arm64"    # static docker uses arm64
    COMPOSE_ARCH_V2="aarch64"     # github compose binary uses aarch64 for ARM
    COMPOSE_ARCH_V1="aarch64"
    ;;
  *)
    echo "Unsupported arch: $ARCH"
    exit 1
    ;;
esac

# ----------------- CentOS7 special fallback -----------------
# CentOS 7 does not have Docker 28.x static/RPMs; use 26.1.0 as enterprise fallback for CentOS7
if [[ "$OS" == "centos" && "$CENTOS_VERSION" == "7" ]]; then
  # If requested Docker >= 27.x, fallback to 26.1.0
  if [[ "${DOCKER_VERSION%%.*}" -ge 27 ]]; then
    echo "Notice: CentOS 7 doesn't support Docker ${DOCKER_VERSION}, falling back to Docker 26.1.0 for CentOS7."
    DOCKER_VERSION="26.1.0"
  fi
fi

OUTDIR="docker-offline-${DOCKER_VERSION}-${ARCH_NORM}"
mkdir -p "$OUTDIR"/{rpms,debs,static}
echo "Output dir: $OUTDIR"
echo "Settings: docker=${DOCKER_VERSION}, arch=${ARCH_NORM}, mode=${MODE}, os=${OS}, centos_ver=${CENTOS_VERSION}, ubuntu=${UBUNTU_RELEASE}, compose_v2=${COMPOSE_V2}"

# initialize flags
RPM_OK=false; DEB_OK=false; STATIC_OK=false; COMPOSE_V2_OK=false; COMPOSE_V1_OK=false

# ----------------- RPM download (only if OS=centos and mode allows) -----------------
if [[ ( "$MODE" == "auto" || "$MODE" == "rpm-only" ) && "$OS" == "centos" ]]; then
  echo ">>> Attempting RPM download (centos-style path)..."
  RPM_BASE="https://download.docker.com/linux/centos/${CENTOS_VERSION}/${DOCKER_STATIC_ARCH}/stable/Packages"
  RPM_CANDIDATES=(
    "docker-ce-${DOCKER_VERSION}.${DOCKER_STATIC_ARCH}.rpm"
    "docker-ce-cli-${DOCKER_VERSION}.${DOCKER_STATIC_ARCH}.rpm"
    "containerd.io-${DOCKER_VERSION}.${DOCKER_STATIC_ARCH}.rpm"
    "docker-buildx-plugin-${DOCKER_VERSION}.${DOCKER_STATIC_ARCH}.rpm"
    "docker-compose-plugin-${DOCKER_VERSION}.${DOCKER_STATIC_ARCH}.rpm"
  )
  for p in "${RPM_CANDIDATES[@]}"; do
    url="${RPM_BASE}/${p}"
    out="${OUTDIR}/rpms/${p}"
    if download "$url" "$out"; then RPM_OK=true; continue; fi
    # try simpler name variant without the arch-suffix
    alt="${p%%.*}.rpm"
    alturl="${RPM_BASE}/${alt}"
    altout="${OUTDIR}/rpms/${alt}"
    download "$alturl" "$altout" || true
    [[ -f "$altout" ]] && RPM_OK=true
  done

  if $RPM_OK; then echo "RPMs saved under ${OUTDIR}/rpms"; fi
  if [[ "$MODE" == "rpm-only" ]]; then echo '{}' > "${OUTDIR}/metadata.json"; echo "Done (rpm-only)"; exit 0; fi
fi

# ----------------- DEB download (only if OS=ubuntu and mode allows) -----------------
if [[ ( "$MODE" == "auto" || "$MODE" == "deb-only" ) && "$OS" == "ubuntu" ]]; then
  echo ">>> Attempting DEB download (ubuntu pool)..."
  case "$UBUNTU_RELEASE" in
    20.04) CODENAME="focal";;
    22.04) CODENAME="jammy";;
    24.04) CODENAME="noble";;  # placeholder if needed
    *) CODENAME="jammy";;
  esac
  DEB_BASE="https://download.docker.com/linux/ubuntu/dists/${CODENAME}/pool/stable/${ARCH_NORM}"
  DEB_CANDIDATES=(
    "docker-ce_${DOCKER_VERSION}~ubuntu.${UBUNTU_RELEASE}~${CODENAME}_${ARCH_NORM}.deb"
    "docker-ce-cli_${DOCKER_VERSION}~ubuntu.${UBUNTU_RELEASE}~${CODENAME}_${ARCH_NORM}.deb"
    "containerd.io_${DOCKER_VERSION}_${ARCH_NORM}.deb"
    "docker-buildx-plugin_${DOCKER_VERSION}~ubuntu.${UBUNTU_RELEASE}~${CODENAME}_${ARCH_NORM}.deb"
    "docker-compose-plugin_${DOCKER_VERSION}~ubuntu.${UBUNTU_RELEASE}~${CODENAME}_${ARCH_NORM}.deb"
  )
  for p in "${DEB_CANDIDATES[@]}"; do
    url="${DEB_BASE}/${p}"
    out="${OUTDIR}/debs/${p}"
    if download "$url" "$out"; then DEB_OK=true; continue; fi
    # fallback to simpler name
    simple="${p%%_*}.deb"
    simple_url="${DEB_BASE}/${simple}"
    simple_out="${OUTDIR}/debs/${simple}"
    download "$simple_url" "$simple_out" || true
    [[ -f "$simple_out" ]] && DEB_OK=true
  done

  if $DEB_OK; then echo "DEBs saved under ${OUTDIR}/debs"; fi
  if [[ "$MODE" == "deb-only" ]]; then echo '{}' > "${OUTDIR}/metadata.json"; echo "Done (deb-only)"; exit 0; fi
fi

# ----------------- Static fallback (if allowed) -----------------
if [[ "$MODE" == "auto" || "$MODE" == "static-only" ]]; then
  echo ">>> Attempting static Docker binary..."
  STATIC_URL="https://download.docker.com/linux/static/stable/${DOCKER_STATIC_ARCH}/docker-${DOCKER_VERSION}.tgz"
  STATIC_OUT="${OUTDIR}/static/docker-${DOCKER_VERSION}.tgz"
  if download "$STATIC_URL" "$STATIC_OUT"; then STATIC_OK=true; fi

  # Compose v2 attempts (multiple URL patterns to cover naming differences)
  echo ">>> Attempting Compose v2 binary (preferred) -> ${COMPOSE_V2}"
  COMPOSE_TRIES=(
    "https://github.com/docker/compose/releases/download/${COMPOSE_V2}/docker-compose-linux-${COMPOSE_ARCH_V2}"
    "https://github.com/docker/compose/releases/download/${COMPOSE_V2}/docker-compose-linux-${ARCH_NORM}"
    "https://github.com/docker/compose/releases/download/${COMPOSE_V2}/docker-compose-${COMPOSE_V2}-linux-${COMPOSE_ARCH_V2}"
  )
  for u in "${COMPOSE_TRIES[@]}"; do
    if download "$u" "${OUTDIR}/static/docker-compose"; then
      chmod +x "${OUTDIR}/static/docker-compose"
      COMPOSE_V2_OK=true
      break
    fi
  done

  # fallback: try Compose v1 binary
  echo ">>> Attempting Compose v1 fallback (${COMPOSE_V1})"
  if download "https://github.com/docker/compose/releases/download/${COMPOSE_V1}/docker-compose-Linux-${COMPOSE_ARCH_V1}" "${OUTDIR}/static/docker-compose-v1"; then
    chmod +x "${OUTDIR}/static/docker-compose-v1"
    COMPOSE_V1_OK=true
  fi

  if [[ "$MODE" == "static-only" ]]; then
    echo '{}' > "${OUTDIR}/metadata.json"
    echo "Done (static-only)."
    exit 0
  fi
fi

# ----------------- write metadata -----------------
cat > "${OUTDIR}/metadata.json" <<EOF
{
  "docker_version":"${DOCKER_VERSION}",
  "arch":"${ARCH_NORM}",
  "rpm_available": ${RPM_OK},
  "deb_available": ${DEB_OK},
  "static_available": ${STATIC_OK},
  "compose_v2_available": ${COMPOSE_V2_OK},
  "compose_v1_available": ${COMPOSE_V1_OK},
  "os_family":"${OS}",
  "centos_version":"${CENTOS_VERSION:-null}",
  "ubuntu_release":"${UBUNTU_RELEASE:-null}",
  "compose_v2":"${COMPOSE_V2}",
  "generated_at":"$(date -Iseconds)"
}
EOF

echo "=== DONE. output directory: ${OUTDIR} ==="
