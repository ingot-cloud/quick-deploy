## 说明
port: 80, 443, 22
初始密码在 /etc/gitlab/initial_root_password

#### 修改自定义下载地址
 * 进入 Admin Area
 * Settings -> General中选择Visibility and access controls
 * 修改Custom Git clone URL for HTTP(S)即可

#### Clone with SSH
 * 修改/etc/gitlab/gitlab.rb
 * 搜索gitlab_ssh_host，配置主机地址`gitlab_rails['gitlab_ssh_host'] = '192.168.72.90'`
 * 配置主机的 ssh 端口，gitlab_rails['gitlab_shell_ssh_port'] = 40022
