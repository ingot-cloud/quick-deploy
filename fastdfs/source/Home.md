# 环境准备
## 使用的系统软件
| 名称         | 说明           |
|:--|-|
| centos|7.x|
|libfastcommon|FastDFS分离出的公用函数库|
|libserverframe|FastDFS分离出的网络框架|
|FastDFS|FastDFS本体|
|fastdfs-nginx-module|FastDFS和nginx的关联模块|
|nginx|nginx1.15.4|

可以采用yum安装和源码编译两种方式之一。

## yum安装
针对CentOS 7 和 CentOS 8及同类Linux发行版。
先安装FastOS.repo yum源，然后就可以安装FastDFS相关软件包了。

CentOS 7、RHEL 7、Oracle Linux 7、Alibaba Cloud Linux 2、Anolis 7、AlmaLinux 7、Amazon Linux 2、Fedora 27及以下版本：
```shell
rpm -ivh http://www.fastken.com/yumrepo/el7/noarch/FastOSrepo-1.0.0-1.el7.centos.noarch.rpm
```

CentOS 8、Rocky 8、RHEL 8、Oracle Linux 8、Alibaba Cloud Linux 3、Anolis 8、AlmaLinux 8、Amazon Linux 3、Fedora 28及以上版本：

```shell
rpm -ivh http://www.fastken.com/yumrepo/el8/noarch/FastOSrepo-1.0.0-1.el8.noarch.rpm
```

安装 FastDFS软件包：
```shell
yum install fastdfs-server fastdfs-tool fastdfs-config -y
```

## 编译环境
CentOS
```shell
yum install git gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel wget vim -y
```
Debian
```
apt-get -y install git gcc g++ make automake autoconf libtool pcre2-utils libpcre2-dev zlib1g zlib1g-dev openssl libssh-dev wget vim
```
## 磁盘目录
|说明|位置|
|-|-|
|所有安装包|/usr/local/src|
|数据存储位置|/home/dfs/|
#这里我为了方便把日志什么的都放到了dfs
```shell
mkdir /home/dfs #创建数据存储目录
cd /usr/local/src #切换到安装目录准备下载安装包
```
## 安装libfastcommon
```shell
git clone https://github.com/happyfish100/libfastcommon.git --depth 1
cd libfastcommon/
./make.sh && ./make.sh install #编译安装
```

## 安装libserverframe
```shell
git clone https://github.com/happyfish100/libserverframe.git --depth 1
cd libserverframe/
./make.sh && ./make.sh install #编译安装
```

## 安装FastDFS
```shell
cd ../ #返回上一级目录
git clone https://github.com/happyfish100/fastdfs.git --depth 1
cd fastdfs/
./make.sh && ./make.sh install #编译安装
#配置文件准备
cp /usr/local/src/fastdfs/conf/http.conf /etc/fdfs/ #供nginx访问使用
cp /usr/local/src/fastdfs/conf/mime.types /etc/fdfs/ #供nginx访问使用
```
## 安装fastdfs-nginx-module
```shell
cd ../ #返回上一级目录
git clone https://github.com/happyfish100/fastdfs-nginx-module.git --depth 1
cp /usr/local/src/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs
```
## 安装nginx
```shell
wget http://nginx.org/download/nginx-1.15.4.tar.gz #下载nginx压缩包
tar -zxvf nginx-1.15.4.tar.gz #解压
cd nginx-1.15.4/
#添加fastdfs-nginx-module模块
./configure --add-module=/usr/local/src/fastdfs-nginx-module/src/ 
make && make install #编译安装
```
# 单机部署

## tracker配置

```shell
#服务器ip为 192.168.52.1
#我建议用ftp下载下来这些文件 本地修改
vim /etc/fdfs/tracker.conf
#需要修改的内容如下
port=22122  # tracker服务器端口（默认22122,一般不修改）
base_path=/home/dfs  # 存储日志和数据的根目录
```
## storage配置
```shell
vim /etc/fdfs/storage.conf
#需要修改的内容如下
port=23000  # storage服务端口（默认23000,一般不修改）
base_path=/home/dfs  # 数据和日志文件存储根目录
store_path0=/home/dfs  # 第一个存储目录
tracker_server=192.168.52.1:22122  # tracker服务器IP和端口
http.server_port=8888  # http访问文件的端口(默认8888,看情况修改,和nginx中保持一致)
```
## client测试
```shell
vim /etc/fdfs/client.conf
#需要修改的内容如下
base_path=/home/dfs
tracker_server=192.168.52.1:22122    #tracker服务器IP和端口
#保存后测试,返回ID表示成功 如：group1/M00/00/00/xx.tar.gz
fdfs_upload_file /etc/fdfs/client.conf /usr/local/src/nginx-1.15.4.tar.gz
```
## 配置nginx访问
```shell
vim /etc/fdfs/mod_fastdfs.conf
#需要修改的内容如下
tracker_server=192.168.52.1:22122  #tracker服务器IP和端口
url_have_group_name=true
store_path0=/home/dfs
#配置nginx.config
vim /usr/local/nginx/conf/nginx.conf
#添加如下配置
server {
    listen       8888;    ## 该端口为storage.conf中的http.server_port相同
    server_name  localhost;
    location ~/group[0-9]/ {
        ngx_fastdfs_module;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    root   html;
    }
}
#测试下载，用外部浏览器访问刚才已传过的nginx安装包,引用返回的ID
http://192.168.52.1:8888/group1/M00/00/00/wKgAQ1pysxmAaqhAAA76tz-dVgg.tar.gz
#弹出下载单机部署全部跑通
```
# 分布式部署

## tracker配置

```shell
#服务器ip为 192.168.52.2,192.168.52.3,192.168.52.4
#我建议用ftp下载下来这些文件 本地修改
vim /etc/fdfs/tracker.conf
#需要修改的内容如下
port=22122  # tracker服务器端口（默认22122,一般不修改）
base_path=/home/dfs  # 存储日志和数据的根目录
```
## storage配置
```shell
vim /etc/fdfs/storage.conf
#需要修改的内容如下
port=23000  # storage服务端口（默认23000,一般不修改）
base_path=/home/dfs  # 数据和日志文件存储根目录
store_path0=/home/dfs  # 第一个存储目录
tracker_server=192.168.52.2:22122  # 服务器1
tracker_server=192.168.52.3:22122  # 服务器2
tracker_server=192.168.52.4:22122  # 服务器3
http.server_port=8888  # http访问文件的端口(默认8888,看情况修改,和nginx中保持一致)
```
## client测试
```shell
vim /etc/fdfs/client.conf
#需要修改的内容如下
base_path=/home/moe/dfs
tracker_server=192.168.52.2:22122  # 服务器1
tracker_server=192.168.52.3:22122  # 服务器2
tracker_server=192.168.52.4:22122  # 服务器3
#保存后测试,返回ID表示成功 如：group1/M00/00/00/xx.tar.gz
fdfs_upload_file /etc/fdfs/client.conf /usr/local/src/nginx-1.15.4.tar.gz
```
## 配置nginx访问
```shell
vim /etc/fdfs/mod_fastdfs.conf
#需要修改的内容如下
tracker_server=192.168.52.2:22122  # 服务器1
tracker_server=192.168.52.3:22122  # 服务器2
tracker_server=192.168.52.4:22122  # 服务器3
url_have_group_name=true
store_path0=/home/dfs
#配置nginx.config
vim /usr/local/nginx/conf/nginx.conf
#添加如下配置
server {
    listen       8888;    ## 该端口为storage.conf中的http.server_port相同
    server_name  localhost;
    location ~/group[0-9]/ {
        ngx_fastdfs_module;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    root   html;
    }
}
```

# 启动
## 防火墙
```shell
#不关闭防火墙的话无法使用
systemctl stop firewalld.service #关闭
systemctl restart firewalld.service #重启
```

## tracker
```shell
修改 /usr/lib/systemd/system/fdfs_trackerd.service 中的 PIDFile，格式为：
PIDFile=$base_path/data/fdfs_trackerd.pid
比如：
PIDFile=/home/dfs/data/fdfs_trackerd.pid
```

```shell
systemctl start fdfs_trackerd #启动tracker服务
systemctl restart fdfs_trackerd #重启动tracker服务
systemctl stop fdfs_trackerd #停止tracker服务
systemctl enable fdfs_trackerd  #开机自启动
```

## storage
```shell
修改 /usr/lib/systemd/system/fdfs_storaged.service 中的 PIDFile，格式为：
PIDFile=$base_path/data/fdfs_storaged.pid
比如：
PIDFile=/home/dfs/data/fdfs_storaged.pid
```

```shell
systemctl start fdfs_storaged #启动storage服务
systemctl restart fdfs_storaged  #重动storage服务
systemctl stop fdfs_storaged  #停止动storage服务
systemctl enable fdfs_storaged   #开机自启动
```

## nginx
```shell
/usr/local/nginx/sbin/nginx #启动nginx
/usr/local/nginx/sbin/nginx -s reload #重启nginx
/usr/local/nginx/sbin/nginx -s stop #停止nginx
```
## 检测集群
```shell
/usr/bin/fdfs_monitor /etc/fdfs/storage.conf
# 会显示会有几台服务器 有3台就会 显示 Storage 1-Storage 3的详细信息
```
# 说明

## 配置文件
```shell
tracker_server #有几台服务器写几个
group_name #地址的名称的命名
bind_addr #服务器ip绑定
store_path_count #store_path(数字)有几个写几个
store_path(数字) #设置几个储存地址写几个 从0开始
```
## 可能遇到的问题
```shell
如果不是root 用户 你必须在除了cd的命令之外 全部加sudo
如果不是root 用户 编译和安装分开进行 先编译再安装
如果上传成功 但是nginx报错404 先检查mod_fastdfs.conf文件中的store_path0是否一致
如果nginx无法访问 先检查防火墙 和 mod_fastdfs.conf文件tracker_server是否一致
如果不是在/usr/local/src文件夹下安装 可能会编译出错
如果 unknown directive "ngx_fastdfs_module" in /usr/local/nginx/conf/nginx.conf:151，可能是nginx一直是启动的，必须要重启nginx才可以，`nginx -s reload`无效。
如果nginx的error.log中提示：ERROR - file: ini_file_reader.c, line: 1051, include file "http.conf" not exists, line: "#include http.conf"
ERROR - file: /root/fastdfs-nginx-module/src/common.c, line: 163, load conf file "/etc/fdfs/mod_fastdfs.conf" fail, ret code: 2
则 需要将fastdfs的源码中的conf文件夹中的http.conf和mime.types cp到 etc/fdf文件夹中。
```
教程是在上一位huayanYu(小锅盖)的基础上添加了一些东西，本质上还是huayanYu(小锅盖)写的教程