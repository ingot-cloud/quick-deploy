## 说明

### 端口以及初始化配置
  * port: 80, 443, 22
  * 初始密码在 /etc/gitlab/initial_root_password

### Nginx
  * 修改nginx `client_max_body_size`
    1. 在/etc/gitlab/gitlab.rb找到nginx配置
    2. 修改 nginx['client_max_body_size'] = '1024m'
    3. 执行命令 gitlab-ctl reconfigure

### Clone地址
#### 1.Clone with Https
  * 进入 Admin Area
  * Settings -> General中选择Visibility and access controls
  * 修改Custom Git clone URL for HTTP(S)即可

#### 2.Clone with SSH
  * 修改/etc/gitlab/gitlab.rb
  * 搜索gitlab_ssh_host，配置主机地址`gitlab_rails['gitlab_ssh_host'] = '192.168.72.90'`
  * 配置主机的 ssh 端口，gitlab_rails['gitlab_shell_ssh_port'] = 40022


### Runner
  1. 运行gitlab-runner.sh
  2. 进入控制台执行`gitlab-runner register`
  3. 按要求输入相关信息即可
  ```
  Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
  https://gitlab.wangchao.im/

  Please enter the gitlab-ci token for this runner:
  pnsBhDZy_iYH_xxxxxx

  Please enter the gitlab-ci description for this runner:
  [96b8ba5db706]: test_runner

  Please enter the gitlab-ci tags for this runner (comma separated):
  test

  Please enter the executor: ssh, kubernetes, shell, docker, docker-ssh, parallels, virtualbox, docker+machine, docker-ssh+machine, custom:
  docker

  Please enter the default Docker image (e.g. ruby:2.6):
  docker:20.10.9

  ```
