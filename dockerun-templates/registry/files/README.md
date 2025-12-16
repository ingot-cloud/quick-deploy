# Registry Basic Auth

假设`WORK_DIR=/opt/registry`

1. 安装 htpasswd（宿主机）
```shell
# centos / rhel
yum install -y httpd-tools

# ubuntu
apt install -y apache2-utils
```
2. 创建用户
```shell
mkdir -p /opt/registry/auth

htpasswd -Bc /opt/registry/auth/htpasswd admin
# 再加一个用户
htpasswd -B /opt/registry/auth/htpasswd dev
```
3. Registry 配置
```yml
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd
```