#!/usr/bin/env bash
set -euo pipefail

# install-offline.sh (FINAL)
# Usage: sudo ./install-offline.sh /path/to/docker-offline-<version>-<arch>

PKG_DIR="${1:-.}"
PKG_DIR="$(cd "$PKG_DIR" && pwd)"
echo "Installing from package dir: $PKG_DIR"

log() { echo "[install] $*"; }

is_rpm() { command -v rpm >/dev/null 2>&1 || [[ -f /etc/redhat-release ]]; }
is_dpkg() { command -v dpkg >/dev/null 2>&1 || [[ -f /etc/debian_version ]]; }

has_rpms() { ls "$PKG_DIR"/rpms/*.rpm >/dev/null 2>&1 || return 1; }
has_debs() { ls "$PKG_DIR"/debs/*.deb >/dev/null 2>&1 || return 1; }
has_static() { ls "$PKG_DIR"/static/docker-*.tgz >/dev/null 2>&1 || ls "$PKG_DIR"/docker-*.tgz >/dev/null 2>&1 || return 1; }

# 1) Try RPM install (if rpm-capable and rpms available)
if is_rpm && has_rpms; then
  log "Detected RPM-capable system and RPM packages present. Installing..."
  sudo rpm -Uvh --force --nodeps "$PKG_DIR"/rpms/*.rpm || true
  if command -v dnf >/dev/null 2>&1; then
    log "Attempting dnf local resolution (skip-broken)..."
    sudo dnf install -y --skip-broken || true
  fi
  sudo systemctl daemon-reload || true
  sudo systemctl enable --now docker || true
  sudo systemctl enable --now containerd || true
  log "RPM installation complete."
  exit 0
fi

# 2) Try DEB install (if deb-capable and debs available)
if is_dpkg && has_debs; then
  log "Detected DEB-capable system and DEB packages present. Installing..."
  sudo dpkg -i "$PKG_DIR"/debs/*.deb || {
    log "dpkg had issues; trying apt-get -f install -y (may fail offline)"
    sudo apt-get update || true
    sudo apt-get -f install -y || true
  }
  sudo systemctl daemon-reload || true
  sudo systemctl enable --now docker || true
  log "DEB installation complete."
  exit 0
fi

# 3) Static fallback install
if has_static; then
  log "Proceeding with static installation..."
  STATIC_TGZ="$(ls "$PKG_DIR"/static/docker-*.tgz 2>/dev/null || true)"
  if [[ -z "$STATIC_TGZ" ]]; then STATIC_TGZ="$(ls "$PKG_DIR"/docker-*.tgz 2>/dev/null || true)"; fi
  if [[ -z "$STATIC_TGZ" ]]; then log "ERROR: static tarball not found"; exit 2; fi

  tmpdir="$(mktemp -d)"
  log "Extracting $STATIC_TGZ -> $tmpdir"
  tar -xzf "$STATIC_TGZ" -C "$tmpdir"

  BIN_SRC="$tmpdir/docker"
  if [[ ! -d "$BIN_SRC" ]]; then BIN_SRC="$tmpdir"; fi

  log "Copying binaries to /usr/bin (fallback /usr/local/bin)..."
  sudo mkdir -p /usr/bin /usr/local/bin
  sudo cp -a "$BIN_SRC"/* /usr/bin/ || sudo cp -a "$BIN_SRC"/* /usr/local/bin/ || true

  # minimal daemon.json if not exists
  if [[ ! -f /etc/docker/daemon.json ]]; then
    log "Creating /etc/docker/daemon.json"
    echo '{"log-level":"info"}' | sudo tee /etc/docker/daemon.json >/dev/null
  fi

  # install compose v2 plugin if provided
  if [[ -f "$PKG_DIR"/static/docker-compose ]]; then
    log "Installing compose v2 plugin to /usr/local/lib/docker/cli-plugins/docker-compose"
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo cp "$PKG_DIR"/static/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    log "Compose v2 plugin installed (note: plugin support with static docker may vary)."
  fi

  # install compose v1 fallback if provided
  if [[ -f "$PKG_DIR"/static/docker-compose-v1 ]]; then
    log "Installing compose v1 to /usr/bin/docker-compose"
    sudo cp "$PKG_DIR"/static/docker-compose-v1 /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose
  fi

  # containerd systemd unit if containerd exists
  if command -v containerd >/dev/null 2>&1 || [[ -f /usr/bin/containerd || -f /usr/local/bin/containerd ]]; then
    log "Writing systemd unit for containerd"
    sudo tee /etc/systemd/system/containerd.service >/dev/null <<'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStart=/usr/bin/containerd
Restart=always
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
  fi

  # docker systemd unit
  log "Writing systemd unit for docker"
  sudo tee /etc/systemd/system/docker.service >/dev/null <<'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target containerd.service
Wants=containerd.service

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd || true
  sudo systemctl enable --now docker || true

  # verification
  if command -v docker >/dev/null 2>&1; then
    log "docker: $(docker --version 2>/dev/null || echo 'unknown')"
    docker info || true
  else
    log "Warning: docker binary not found after installation"
  fi

  log "Static installation finished."
  exit 0
fi

echo "No installable packages found in $PKG_DIR (rpms/debs/static)."
exit 3
