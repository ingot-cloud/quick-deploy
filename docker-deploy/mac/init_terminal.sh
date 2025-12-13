#!/bin/bash

echo "=== 🚀 macOS 15.6 终端环境一键初始化（SSH 批量导入 + 重复检测 + 快捷登录） ==="

# === 检查 brew ===
if ! command -v brew &> /dev/null; then
    echo "📦 正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ 已检测到 Homebrew"
fi

brew update

# === 安装常用工具 ===
echo "📦 安装终端工具..."
brew install --cask iterm2 warp termius
brew install zsh fzf tmux zsh-autosuggestions zsh-syntax-highlighting

# === 安装 Oh My Zsh ===
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 安装 Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "✅ 已检测到 Oh My Zsh"
fi

# === 配置 Zsh 插件 ===
echo "⚙️ 配置 Zsh 插件..."
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    sed -i '' 's/^plugins=(/plugins=(zsh-autosuggestions zsh-syntax-highlighting /' ~/.zshrc
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# === 配置 fzf ===
"$(brew --prefix)/opt/fzf/install" --all --key-bindings --completion --no-bash

# === SSH Config 初始化 ===
SSH_CONFIG_FILE="$HOME/.ssh/config"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch "$SSH_CONFIG_FILE"
chmod 600 "$SSH_CONFIG_FILE"

# === SSH 批量导入功能（含重复检测） ===
IMPORT_FILE="$HOME/ssh_hosts.txt"
if [ -f "$IMPORT_FILE" ]; then
    echo "📦 从 $IMPORT_FILE 批量导入 SSH 主机配置..."
    while IFS=',' read -r host alias user keyfile port; do
        [ -z "$host" ] && continue
        # 检测别名是否已存在
        if grep -q "^Host[[:space:]]\+$alias" "$SSH_CONFIG_FILE"; then
            echo "⚠️ 别名 '$alias' 已存在，跳过导入"
            continue
        fi
        {
            echo "Host $alias"
            echo "    HostName $host"
            echo "    User ${user:-root}"
            [ -n "$keyfile" ] && echo "    IdentityFile ${keyfile/#\~/$HOME}"
            [ -n "$port" ] && echo "    Port $port"
            echo ""
        } >> "$SSH_CONFIG_FILE"
        echo "✅ 已导入主机 $alias ($host)"
    done < "$IMPORT_FILE"
else
    echo "⚠️ 未检测到 $IMPORT_FILE，跳过批量导入"
    echo "💡 创建 $IMPORT_FILE，格式：IP/域名,别名,用户名,私钥路径,端口"
    echo "示例："
    echo "    192.168.1.10,myserver,ubuntu,~/.ssh/id_rsa,22"
    echo "    10.0.0.5,test,root,,2222"
fi

# === 添加 sshc 快捷命令 ===
if ! grep -q "function sshc()" ~/.zshrc; then
    echo "📦 添加 sshc 快捷命令到 .zshrc..."
    cat >> ~/.zshrc <<'EOF'

# SSH 快捷连接
function sshc() {
    local host
    host=$(grep -i "^Host " ~/.ssh/config | grep -v "*" | awk '{print $2}' | fzf --prompt="Select SSH Host: ")
    if [ -n "$host" ]; then
        echo "🔗 正在连接 $host ..."
        ssh "$host"
    fi
}
EOF
fi

# === 刷新 shell ===
echo "🔄 重新加载 Zsh..."
source ~/.zshrc

echo "🎉 初始化完成！"
echo "💡 使用方法："
echo "   1. 编辑 $HOME/ssh_hosts.txt 按格式填写主机信息"
echo "   2. 再次运行脚本批量导入"
echo "   3. 输入 sshc → 模糊搜索主机 → 自动连接"
