# 变更日志

本文档记录Docker部署脚本的所有重要变更。

## [2.0.1] - 2024-12-10

### 🐛 Bug修复

#### 1. DEB包下载URL错误修复
- **问题**: Ubuntu DEB包下载时URL构建错误,导致404错误
- **原因**: 包文件名格式错误,缺少包名前缀
- **修复**: 修正DEB包文件名格式为 `包名_版本号_架构.deb`
- **影响**: 修复前Ubuntu离线包下载完全失败,修复后可正常下载

**修复详情:**
- 错误格式: `5:27.4.1-1~ubuntu.22.04~jammy_amd64.deb`
- 正确格式: `docker-ce_27.4.1-1~ubuntu.22.04~jammy_amd64.deb`

#### 2. RPM包版本号问题修复
- **问题**: containerd.io, buildx-plugin, compose-plugin下载失败
- **原因**: 这些包有独立的版本号,不跟随Docker版本
- **修复**: 
  - 为不同的包指定独立的版本号
  - 添加多版本fallback机制
  - containerd.io使用1.7.22等版本
  - buildx-plugin使用0.17.1等版本
  - compose-plugin使用2.29.7等版本
- **影响**: 提高了RPM包下载的成功率

**版本号映射:**
```
Docker 26.1.4 搭配:
  - docker-ce: 26.1.4
  - docker-ce-cli: 26.1.4
  - containerd.io: 1.7.22
  - docker-buildx-plugin: 0.17.1
  - docker-compose-plugin: 2.29.7
```

### ✨ 新增功能

#### 版本查询工具
- 新增 `list-available-versions.sh` 脚本
- 可查询Docker官方仓库中实际可用的包版本
- 帮助用户确定正确的版本号

### 📚 文档改进

- 添加两个安装脚本(install.sh vs install-docker-offline.sh)的对比说明
- 添加DEB/RPM包下载失败的故障排查指南
- 添加常见问题解答(FAQ)关于包版本的说明
- 强调使用静态二进制模式的优势

### 💡 使用建议更新

**推荐下载模式:**
1. **静态二进制模式**(推荐) - 最通用,不受包版本影响
   ```bash
   ./download-docker-offline.sh --download-mode static
   ```

2. **all模式** - 下载所有格式,但可能因版本问题部分失败
   ```bash
   ./download-docker-offline.sh --download-mode all
   ```

3. **查询版本后再下载** - 确保版本正确
   ```bash
   ./list-available-versions.sh ubuntu 22.04 amd64
   # 根据输出调整脚本中的版本号
   ```

---

## [2.0.0] - 2024-12-10

### 🎉 重大更新 - 企业级脚本重构

完全重写了Docker部署脚本,提供更强大、更易用的企业级解决方案。

### ✨ 新增功能

#### 1. 在线安装脚本 (`install-docker-online.sh`)
- ✅ 全新的在线安装脚本,支持直接在有网络的服务器上安装
- ✅ 交互式和非交互式两种模式
- ✅ 支持自定义Docker和Compose版本
- ✅ 支持CentOS 7/8/9/Stream和Ubuntu 20.04/22.04/24.04
- ✅ 支持amd64和arm64架构
- ✅ 自动检测系统类型和架构
- ✅ 智能处理依赖和仓库配置
- ✅ 完整的安装验证流程
- ✅ 彩色日志输出,清晰易读

#### 2. 离线下载脚本 (`download-docker-offline.sh`)
- ✅ 支持在Mac和Linux上运行
- ✅ 交互式配置,用户友好
- ✅ 支持下载RPM包(CentOS/RHEL)
- ✅ 支持下载DEB包(Ubuntu/Debian)
- ✅ 支持下载静态二进制文件(通用)
- ✅ 多架构支持(amd64/arm64)
- ✅ 自动生成安装脚本
- ✅ 生成详细的README和元数据
- ✅ 智能URL构建和多重fallback
- ✅ 重试机制,提高下载成功率

#### 3. 离线安装脚本 (`install-docker-offline.sh`)
- ✅ 完全重写,更加健壮
- ✅ 自动检测系统类型并选择合适的安装方式
- ✅ 支持RPM/DEB/Static三种安装方式
- ✅ 智能fallback机制
- ✅ 完整的systemd服务配置
- ✅ 自动配置Docker daemon.json
- ✅ 支持Docker Compose插件和二进制
- ✅ 详细的安装验证
- ✅ 友好的后续步骤提示

### 📚 文档改进

#### 新增文档
- ✅ `README.md` - 完整的使用文档和故障排查指南
- ✅ `QUICKSTART.md` - 5分钟快速入门指南
- ✅ `CHANGELOG.md` - 本变更日志
- ✅ 离线包自动生成README.md

#### 文档特性
- 详细的使用示例
- 完整的部署流程说明
- 常见问题解答
- 故障排查指南
- 最佳实践建议
- 表格化的系统支持列表

### 🛠️ 技术改进

#### 代码质量
- ✅ 完整的错误处理(`set -euo pipefail`)
- ✅ 彩色日志输出,提升用户体验
- ✅ 模块化函数设计
- ✅ 详细的注释和文档字符串
- ✅ 通过shellcheck检查,无lint错误

#### 兼容性
- ✅ 支持更多操作系统版本
- ✅ 支持多架构(amd64/arm64)
- ✅ Mac兼容性(下载脚本)
- ✅ 向后兼容Docker Compose v1和v2

#### 安全性
- ✅ 权限检查(需要root)
- ✅ 输入验证
- ✅ 安全的默认配置
- ✅ 日志轮转配置

#### 可靠性
- ✅ 网络下载重试机制
- ✅ 多重URL fallback
- ✅ 服务启动等待和验证
- ✅ 依赖检查

### 🗑️ 移除内容

- ❌ 删除旧的 `offline-docker-builder.sh`
- ❌ 删除旧的 `install-offline.sh`

### 📦 版本信息

#### 默认版本
- Docker: 27.4.1
- Docker Compose: v2.30.3
- containerd: 1.7.24 (静态包)

#### 支持的系统
- CentOS: 7, 8, 9, Stream
- Ubuntu: 20.04, 22.04, 24.04
- 架构: amd64 (x86_64), arm64 (aarch64)

### 🔄 迁移指南

#### 从旧脚本迁移

如果你之前使用的是旧版本的脚本:

**在线安装**
```bash
# 旧方式: 手动配置仓库和安装
# 新方式: 一个脚本搞定
sudo ./install-docker-online.sh
```

**离线下载**
```bash
# 旧方式:
./offline-docker-builder.sh 28.4.0 amd64 --mode auto --os centos --os-version 8

# 新方式:
./download-docker-offline.sh --docker-version 27.4.1 --os-type centos --os-version 8 --arch amd64
```

**离线安装**
```bash
# 旧方式:
sudo ./install-offline.sh /path/to/offline-package

# 新方式(推荐):
cd docker-offline-27.4.1-centos8-amd64
sudo ./install.sh

# 或使用独立脚本:
sudo ./install-docker-offline.sh /path/to/offline-package
```

### 💡 使用建议

1. **首次使用** - 建议先阅读 `QUICKSTART.md`
2. **生产环境** - 建议使用离线安装方式
3. **开发环境** - 可以使用在线安装方式
4. **企业部署** - 参考 `README.md` 中的完整流程

### 🐛 已知问题

暂无

### 🔮 未来计划

- [ ] 支持更多Linux发行版(Debian, Fedora等)
- [ ] 添加Docker版本自动检测和推荐
- [ ] 支持批量服务器部署
- [ ] 添加回滚功能
- [ ] 支持自定义镜像仓库配置
- [ ] 添加性能优化建议
- [ ] 集成监控和告警配置

---

## [1.0.0] - 2024-12-09

### 初始版本

- 基础的离线包构建脚本
- 基础的离线安装脚本
- 支持CentOS和Ubuntu
- 支持RPM、DEB和静态二进制

---

**注释**: 版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

