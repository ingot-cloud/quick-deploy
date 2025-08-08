# 

## init_terminal.sh脚本效果
 - 安装 Homebrew（如果没有）
 - 安装 iTerm2 + Warp（两个终端可随意用）
 - 安装 Termius（SSH 可视化管理）
 - 安装 Zsh、Oh My Zsh、Powerlevel10k 美化
 - 安装 fzf（模糊搜索）、tmux（终端多路复用）
 - 配好自动补全、命令提示、语法高亮

## 批量导入文件示例（ssh_hosts.txt）
 - 路径：~/ssh_hosts.txt
 - 格式：
```bash
IP或域名,别名,用户名,私钥路径,端口
192.168.1.10,myserver,ubuntu,~/.ssh/id_rsa,22
10.0.0.5,test,root,,2222
```
 - 私钥路径 可留空（走默认 ~/.ssh/id_rsa）
 - 端口 可留空（走默认 22）