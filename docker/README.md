# Docker 部署脚本集合

企业级Docker在线和离线部署解决方案,支持CentOS和Ubuntu系统。

## 📋 脚本说明

### 1. install-docker-online.sh - 在线安装脚本

在有互联网连接的服务器上直接安装Docker和Docker Compose。

**特性:**
- ✅ 支持CentOS 7/8/9/Stream
- ✅ 支持Ubuntu 20.04/22.04/24.04  
- ✅ 支持amd64和arm64架构
- ✅ 交互式和非交互式安装
- ✅ 可自定义Docker和Compose版本
- ✅ 自动配置systemd服务
- ✅ 支持Compose插件或二进制安装

**使用方法:**

```bash
# 交互式安装(推荐新手)
sudo ./install-docker-online.sh

# 非交互式安装(自动化部署)
sudo ./install-docker-online.sh \
  --docker-version 27.4.1 \
  --compose-version v2.30.3 \
  --compose-mode plugin

# 安装最新版本
sudo ./install-docker-online.sh --docker-version latest
```

### 2. download-docker-offline.sh - 离线包下载脚本

在有互联网的机器(Mac或Linux)上下载Docker离线安装包。

**特性:**
- ✅ 支持在Mac上运行
- ✅ 下载RPM包(CentOS/RHEL)
- ✅ 下载DEB包(Ubuntu/Debian)
- ✅ 下载静态二进制(通用)
- ✅ 自动生成安装脚本
- ✅ 支持多架构(amd64/arm64)
- ✅ 可选下载模式

**使用方法:**

```bash
# 交互式下载
./download-docker-offline.sh

# 下载CentOS 8 amd64离线包
./download-docker-offline.sh \
  --docker-version 27.4.1 \
  --compose-version v2.30.3 \
  --os-type centos \
  --os-version 8 \
  --arch amd64

# 下载Ubuntu 22.04 arm64离线包
./download-docker-offline.sh \
  --docker-version 27.4.1 \
  --os-type ubuntu \
  --os-version 22.04 \
  --arch arm64

# 只下载静态二进制(通用于所有Linux)
./download-docker-offline.sh \
  --download-mode static \
  --arch amd64
```

### 3. install-docker-offline.sh - 离线安装脚本(独立版)

在目标服务器上安装离线包。

**两种安装脚本的区别:**

| 特性 | install.sh (自动生成) | install-docker-offline.sh (独立) |
|------|---------------------|------------------------------|
| 来源 | 下载脚本自动生成 | 仓库中独立提供 |
| 依赖 | 与离线包绑定 | 可独立使用 |
| 适用场景 | 使用download脚本下载的包 | 手动准备的离线包或作为备份 |
| 推荐度 | ✅ 推荐(更贴合当前包) | ⭐ 通用版本 |

**使用方法:**

```bash
# 方式1: 使用下载脚本生成的安装脚本(推荐)
cd docker-offline-27.4.1-centos8-amd64/
sudo ./install.sh

# 方式2: 使用独立的离线安装脚本
sudo ./install-docker-offline.sh /path/to/docker-offline-xxx
```

**为什么保留两个脚本?**
- `install.sh` 是针对当前离线包定制的,与包版本完美匹配
- `install-docker-offline.sh` 是通用版本,可以:
  - 处理手动准备的离线包
  - 作为参考实现
  - 在自动生成脚本出问题时作为备份

### 4. list-available-versions.sh - 版本查询工具

查询Docker官方仓库中可用的包版本。

**使用方法:**

```bash
# 查询Ubuntu 22.04 amd64可用版本
./list-available-versions.sh ubuntu 22.04 amd64

# 查询CentOS 8 x86_64可用版本
./list-available-versions.sh centos 8 x86_64
```

**为什么需要这个工具?**
- Docker的插件版本(compose-plugin, buildx-plugin)经常更新
- containerd版本可能与Docker版本不同步
- 帮助确定实际可下载的版本号

### 5. config.example - 配置参考文件

**注意**: 这个文件目前**不会被脚本读取**,仅作为配置参考。

**作用:**
- 📖 展示所有可配置的参数
- 📝 提供配置示例
- 💡 帮助理解脚本的配置选项

**使用方式:**

脚本目前通过**命令行参数**配置,不读取配置文件:

```bash
# 直接使用命令行参数(当前方式)
./download-docker-offline.sh \
  --docker-version 27.4.1 \
  --compose-version v2.30.3 \
  --os-type centos

# 或者使用环境变量
export DOCKER_VERSION=27.4.1
./download-docker-offline.sh --non-interactive
```

如果未来需要配置文件功能,可以参考这个示例实现。

## 🚀 完整部署流程

### 场景1: 在线直接安装

适用于有互联网连接的服务器:

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/your-repo/quick-deploy/main/docker/install-docker-online.sh

# 2. 添加执行权限
chmod +x install-docker-online.sh

# 3. 执行安装
sudo ./install-docker-online.sh
```

### 场景2: 离线安装(推荐企业环境)

适用于无互联网或受限网络环境:

#### 步骤1: 在有网络的机器上下载离线包

```bash
# 在Mac或联网的Linux机器上
./download-docker-offline.sh \
  --docker-version 27.4.1 \
  --os-type centos \
  --os-version 8 \
  --arch amd64

# 生成的目录: docker-offline-27.4.1-centos8-amd64/
```

#### 步骤2: 传输到目标服务器

```bash
# 打包
tar -czf docker-offline.tar.gz docker-offline-27.4.1-centos8-amd64/

# 传输到目标服务器
scp docker-offline.tar.gz user@target-server:/opt/

# 或使用U盘、内网文件服务器等方式传输
```

#### 步骤3: 在目标服务器上安装

```bash
# 解压
cd /opt
tar -xzf docker-offline.tar.gz
cd docker-offline-27.4.1-centos8-amd64/

# 执行安装
sudo ./install.sh

# 验证
docker --version
docker compose version
docker run --rm hello-world
```

#### 步骤4: 配置用户权限

```bash
# 将当前用户添加到docker组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker

# 验证(不需要sudo)
docker ps
```

## 📦 支持的版本

### Docker版本
- 推荐: 27.4.1, 26.1.0, 25.0.5
- 支持: Docker CE 所有版本

### Docker Compose版本
- 推荐: v2.30.3, v2.29.0
- 支持: v2.x 所有版本

### 操作系统

| 系统 | 版本 | 架构 | 状态 |
|------|------|------|------|
| CentOS | 7 | amd64/arm64 | ✅ 支持 |
| CentOS | 8 | amd64/arm64 | ✅ 支持 |
| CentOS | 9 | amd64/arm64 | ✅ 支持 |
| CentOS | Stream | amd64/arm64 | ✅ 支持 |
| Ubuntu | 20.04 | amd64/arm64 | ✅ 支持 |
| Ubuntu | 22.04 | amd64/arm64 | ✅ 支持 |
| Ubuntu | 24.04 | amd64/arm64 | ✅ 支持 |

## 🔧 高级配置

### 自定义Docker配置

编辑 `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "registry-mirrors": [
    "https://your-mirror.com"
  ],
  "insecure-registries": [
    "your-registry.com:5000"
  ]
}
```

重启Docker生效:

```bash
sudo systemctl restart docker
```

### 配置代理

编辑 `/etc/systemd/system/docker.service.d/http-proxy.conf`:

```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
```

重新加载并重启:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 🐛 故障排查

### DEB/RPM包下载失败

**问题**: 下载特定版本的包时返回404错误

**原因**: 
- Docker插件(compose-plugin, buildx-plugin)版本号**不跟随Docker版本**
- containerd.io有**独立的版本号**(如1.7.22)
- buildx-plugin版本号独立(如0.17.1)
- compose-plugin版本号独立(如2.29.7)
- 某些版本可能已从仓库中移除

**版本号说明:**

| 包名 | 版本号规则 | 示例 |
|------|-----------|------|
| docker-ce | 跟随Docker | 26.1.4, 27.4.1 |
| docker-ce-cli | 跟随Docker | 26.1.4, 27.4.1 |
| containerd.io | 独立版本 | 1.7.22, 1.6.33 |
| docker-buildx-plugin | 独立版本 | 0.17.1, 0.16.2 |
| docker-compose-plugin | 独立版本 | 2.29.7, 2.28.1 |

**解决方案**:

```bash
# 方案1: 使用版本查询工具查看可用版本(推荐)
./list-available-versions.sh centos 7 x86_64
./list-available-versions.sh ubuntu 22.04 amd64

# 方案2: 使用静态二进制(最推荐,最通用)
./download-docker-offline.sh \
  --download-mode static \
  --arch amd64

# 方案3: 脚本会自动尝试多个版本
# 新版本的下载脚本会自动尝试常见的版本号

# 方案4: 访问官方仓库手动查看
# Ubuntu: https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/
# CentOS: https://download.docker.com/linux/centos/7/x86_64/stable/Packages/
```

**为什么部分包下载失败也能安装?**
- docker-ce 和 docker-ce-cli 是核心,必须的
- containerd.io 通常已经在静态包中包含
- buildx和compose插件可以单独安装或使用二进制

### Docker服务无法启动

```bash
# 查看服务状态
sudo systemctl status docker

# 查看详细日志
sudo journalctl -xeu docker

# 检查配置文件
sudo dockerd --validate
```

### 权限被拒绝

```bash
# 确认用户在docker组中
groups $USER

# 如果不在,添加并重新登录
sudo usermod -aG docker $USER
newgrp docker
```

### 网络问题

```bash
# 检查Docker网络
docker network ls

# 重建默认网络
sudo systemctl restart docker

# 检查防火墙
sudo systemctl status firewalld
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
```

### 存储驱动问题

```bash
# 查看当前存储驱动
docker info | grep "Storage Driver"

# CentOS 7可能需要使用devicemapper
# 在daemon.json中设置:
{
  "storage-driver": "devicemapper"
}
```

## 📚 常见问题

**Q: 为什么选择这个版本的Docker?**

A: 默认使用27.4.1是稳定的LTS版本,适合生产环境。可根据需求选择其他版本。

**Q: 离线包可以跨系统使用吗?**

A: 不可以。RPM包只能用于RedHat系(CentOS/RHEL),DEB包只能用于Debian系(Ubuntu/Debian)。但static静态二进制可以跨系统使用。

**Q: 如何卸载Docker?**

A: 
```bash
# CentOS
sudo yum remove docker-ce docker-ce-cli containerd.io

# Ubuntu
sudo apt-get purge docker-ce docker-ce-cli containerd.io

# 删除数据(可选)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

**Q: Mac上下载的离线包能用于Linux服务器吗?**

A: 可以。下载脚本只是下载文件,不依赖运行平台。下载的包是针对目标Linux系统的。

**Q: 为什么推荐使用Compose插件而不是二进制?**

A: Compose插件(v2)是官方推荐的方式,性能更好,与Docker CLI集成更紧密,使用`docker compose`而不是`docker-compose`。

**Q: DEB/RPM包下载失败怎么办?**

A: 这是正常现象。Docker的插件包(compose-plugin, buildx-plugin)版本更新频繁,脚本中硬编码的版本可能已不可用。解决方法:
1. 使用`--download-mode static`下载静态二进制(推荐)
2. 使用`./list-available-versions.sh`查询可用版本
3. 静态二进制更通用,不依赖特定系统版本

**Q: install.sh 和 install-docker-offline.sh 有什么区别?**

A: 
- `install.sh` 是下载脚本自动生成的,与离线包版本完美匹配(推荐使用)
- `install-docker-offline.sh` 是独立脚本,可以处理任何符合规范的离线包
- 两者功能基本相同,优先使用自动生成的`install.sh`

## 🔗 相关资源

- [Docker官方文档](https://docs.docker.com/)
- [Docker Compose文档](https://docs.docker.com/compose/)
- [Docker Hub](https://hub.docker.com/)

## 📝 维护说明

脚本维护者应定期:
1. 更新默认Docker版本
2. 更新默认Compose版本
3. 测试新版本操作系统兼容性
4. 更新依赖包版本(如containerd)

## 📄 许可证

本项目遵循 MIT 许可证。
