# 准备工作

## 安装docker
```bash
# yum 包更新
[root@centos7 ~]# yum update
# 卸载旧版本 Docker
[root@centos7 ~]# yum remove docker docker-common docker-selinux docker-engine
# 安装软件包
[root@centos7 ~]# yum install -y yum-utils device-mapper-persistent-data lvm2
# 添加 Docker yum源
[root@centos7 ~]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装 Docker
[root@centos7 ~]# yum -y install docker-ce
# 启动 Docker
[root@centos7 ~]# systemctl start docker
# 查看 Docker 版本号
[root@centos7 ~]# docker —version
```

### 使用阿里云镜像
#### 自动安装
```bash
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

#### apt
```bash
# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
# step 2: 安装GPG证书
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新并安装 Docker-CE
sudo apt-get -y update
sudo apt-get -y install docker-ce
```
#### yum
```bash
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
sudo yum makecache fast
sudo yum -y install docker-ce
# Step 4: 开启Docker服务
sudo service docker start
```

#### 配置镜像加速器
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://9z89zmsy.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```


## 安装docker-compose
```bash
# https://github.com/docker/compose/releases下载最新版docker-compose-linux-x86_64
# 复制到/usr/local/bin/
# 增加权限
chmod +x /usr/local/bin/docker-compose
```

## 离线安装
下载相关包[https://download.docker.com/linux/static/stable/x86_64/](https://download.docker.com/linux/static/stable/x86_64/)

 * 下载相关安装包，比如[https://download.docker.com/linux/static/stable/x86_64/docker-23.0.1.tgz](https://download.docker.com/linux/static/stable/x86_64/docker-23.0.1.tgz)
 * 解压安装包
 ```bash
 tar -zxvf docker-23.0.1.tgz
 ```
 * 复制解压后的文件到/usr/bin/
 ```bash
 cp docker/* /usr/bin/
 ```
 * 创建docker.service文件到/usr/lib/systemd/system/目录下
 ```bash
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
[Service]
Type=notify
EnvironmentFile=-/run/flannel/docker
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/dockerd \
                -H tcp://0.0.0.0:4243 \
                -H unix:///var/run/docker.sock \
                --selinux-enabled=false \
                --log-opt max-size=100m
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
 ```

 * 重新加载daemon-reload
 ```bash
 systemctl daemon-reload
 ```

 * 启动docker
 ```bash
 systemctl start docker
 systemctl enable docker
 ```

