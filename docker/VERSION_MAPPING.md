# Docker包版本号映射参考

> 帮助用户理解Docker各组件的版本号关系

## 📋 版本号规则

Docker及其相关组件的版本号**不是统一的**,需要分别管理:

| 组件 | 版本号来源 | 示例版本 | 说明 |
|------|-----------|---------|------|
| docker-ce | Docker Engine | 26.1.4, 27.4.1 | 主版本 |
| docker-ce-cli | Docker Engine | 26.1.4, 27.4.1 | 跟随docker-ce |
| containerd.io | containerd项目 | 1.7.22, 1.6.33 | **独立版本** |
| docker-buildx-plugin | buildx项目 | 0.17.1, 0.16.2 | **独立版本** |
| docker-compose-plugin | compose项目 | 2.29.7, 2.28.1 | **独立版本** |
| docker-ce-rootless-extras | Docker Engine | 26.1.4, 27.4.1 | 跟随docker-ce |

## 🔗 推荐的版本组合

### Docker 27.4.1 (最新稳定版)

```bash
docker-ce: 27.4.1
docker-ce-cli: 27.4.1
containerd.io: 1.7.22
docker-buildx-plugin: 0.17.1
docker-compose-plugin: 2.29.7
docker-ce-rootless-extras: 27.4.1
```

### Docker 26.1.4 (LTS)

```bash
docker-ce: 26.1.4
docker-ce-cli: 26.1.4
containerd.io: 1.7.22
docker-buildx-plugin: 0.17.1
docker-compose-plugin: 2.29.7
docker-ce-rootless-extras: 26.1.4
```

### Docker 25.0.5

```bash
docker-ce: 25.0.5
docker-ce-cli: 25.0.5
containerd.io: 1.6.33
docker-buildx-plugin: 0.16.2
docker-compose-plugin: 2.28.1
docker-ce-rootless-extras: 25.0.5
```

## 🔍 如何查找可用版本

### 方法1: 使用版本查询脚本(推荐)

```bash
# CentOS
./list-available-versions.sh centos 7 x86_64
./list-available-versions.sh centos 8 x86_64

# Ubuntu
./list-available-versions.sh ubuntu 22.04 amd64
./list-available-versions.sh ubuntu 20.04 amd64
```

### 方法2: 访问官方仓库

**CentOS/RHEL:**
- CentOS 7: https://download.docker.com/linux/centos/7/x86_64/stable/Packages/
- CentOS 8: https://download.docker.com/linux/centos/8/x86_64/stable/Packages/
- CentOS 9: https://download.docker.com/linux/centos/9/x86_64/stable/Packages/

**Ubuntu/Debian:**
- Ubuntu 20.04 (focal): https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/
- Ubuntu 22.04 (jammy): https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/
- Ubuntu 24.04 (noble): https://download.docker.com/linux/ubuntu/dists/noble/pool/stable/amd64/

### 方法3: 查看包文件

下载后的包文件名包含版本信息:

**RPM格式:**
```
docker-ce-26.1.4-1.el7.x86_64.rpm
containerd.io-1.7.22-3.1.el7.x86_64.rpm
docker-buildx-plugin-0.17.1-1.el7.x86_64.rpm
```

**DEB格式:**
```
docker-ce_27.4.1-1~ubuntu.22.04~jammy_amd64.deb
containerd.io_1.7.22-1_amd64.deb
docker-buildx-plugin_0.17.1-1~ubuntu.22.04~jammy_amd64.deb
```

## 🎯 版本选择建议

### 生产环境

**优先级排序:**

1. **使用静态二进制** (最推荐)
   - 不受包版本变化影响
   - 通用于所有Linux发行版
   - 版本一致性最好

```bash
./download-docker-offline.sh --download-mode static --docker-version 27.4.1
```

2. **使用包管理器+确认版本**
   - 先查询可用版本
   - 使用经过验证的版本组合

```bash
./list-available-versions.sh centos 7 x86_64
# 确认版本后下载
```

3. **在线安装**
   - 最简单,自动处理依赖
   - 始终获取最新版本

```bash
sudo ./install-docker-online.sh
```

### 开发/测试环境

可以使用最新版本:

```bash
./install-docker-online.sh --docker-version latest
```

## 🔄 版本更新频率

| 组件 | 更新频率 | 影响 |
|------|---------|------|
| docker-ce | 每月/每季度 | 稳定 |
| containerd.io | 不定期 | 中等 |
| buildx-plugin | 频繁 | 高 |
| compose-plugin | 频繁 | 高 |

**插件版本更新较快**,这也是为什么推荐使用静态二进制或在线安装的原因。

## 📝 版本维护说明

下载脚本中硬编码的版本号需要定期更新:

**更新位置:**
- `download-docker-offline.sh` 的 `download_rpm_packages()` 函数
- `download-docker-offline.sh` 的 `download_deb_packages()` 函数

**更新周期:**
- 建议每季度检查一次
- 主要更新插件版本号
- Docker核心版本按需更新

## 🆘 遇到版本问题怎么办?

### 症状: 404错误,包不存在

**快速解决:**

```bash
# 1. 使用静态二进制(最快)
./download-docker-offline.sh --download-mode static

# 2. 查询可用版本
./list-available-versions.sh [os] [version] [arch]

# 3. 使用在线安装
sudo ./install-docker-online.sh
```

### 症状: 部分包下载失败

**是否影响安装?**

必须的包:
- ✅ docker-ce (必须)
- ✅ docker-ce-cli (必须)

可选的包:
- ⭐ containerd.io (静态包中已包含)
- ⭐ buildx-plugin (可单独安装)
- ⭐ compose-plugin (可单独安装)

**结论**: 只要docker-ce和docker-ce-cli下载成功,就可以安装基础Docker。

## 🔗 相关资源

- [Docker官方发布说明](https://docs.docker.com/engine/release-notes/)
- [containerd发布](https://github.com/containerd/containerd/releases)
- [buildx发布](https://github.com/docker/buildx/releases)
- [compose发布](https://github.com/docker/compose/releases)

---

**提示**: 对于企业环境,强烈建议使用**静态二进制模式**下载,避免版本兼容性问题。

