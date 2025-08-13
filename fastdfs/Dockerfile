# 选择系统镜像作为基础镜像，可以使用超小的Linux镜像alpine
#FROM centos:7
FROM alpine:3.16

# fastdfs v6.12.4

# 0.安装包位置，fdfs的基本目录和存储目录
ENV INSTALL_PATH=/usr/local/src \
  NGINX_VERSION="1.15.4" \
  TENGINE_VERSION="2.3.3" 

# 0.change the system source for installing libs
RUN echo "http://mirrors.aliyun.com/alpine/v3.16/main" > /etc/apk/repositories \
  && echo "http://mirrors.aliyun.com/alpine/v3.16/community" >> /etc/apk/repositories

# 1.复制安装包
ADD source ${INSTALL_PATH}

COPY conf/*.* /etc/fdfs/

# 2.环境安装
# - 创建fdfs的存储目录
# - 安装依赖
# - 安装libfastcommon
# - 安装fastdfs
# - 安装nginx,设置nginx和fastdfs联合环境
#Run yum -y install -y gcc gcc-c++ libevent libevent-devel make automake autoconf libtool perl pcre pcre-devel zlib zlib-devel openssl openssl-devel zip unzip net-tools wget vim lsof  \
RUN  apk update  && apk add --no-cache --virtual .build-deps bash autoconf gcc libc-dev make pcre-dev zlib-dev linux-headers gnupg libxslt-dev gd-dev geoip-dev wget \
  &&  cd ${INSTALL_PATH}  \
  &&  tar -zxf libfastcommon.tar.gz \
  &&  tar -zxf libserverframe.tar.gz \
  &&  tar -zxf fastdfs.tar.gz \
  &&  tar -zxf fastdfs-nginx-module.tar.gz \
  &&  tar -zxf nginx-${NGINX_VERSION}.tar.gz \
      \  
  &&  cd ${INSTALL_PATH}/libfastcommon/ \
  &&  ./make.sh \
  &&  ./make.sh install \
  &&  cd ${INSTALL_PATH}/libserverframe/ \
  &&  ./make.sh \
  &&  ./make.sh install \
  &&  cd ${INSTALL_PATH}/fastdfs/ \
  &&  ./make.sh \
  &&  ./make.sh install \
      \  
  &&  cd ${INSTALL_PATH}/nginx-${NGINX_VERSION}/ \
  &&  ./configure --prefix=/usr/local/nginx --pid-path=/var/run/nginx/nginx.pid --with-http_stub_status_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-stream=dynamic \
      --add-module=${INSTALL_PATH}/fastdfs-nginx-module/src/ \
  &&  make \
  &&  make install \
      \  
  &&  rm -rf ${INSTALL_PATH}/* \
  &&  apk del .build-deps gcc libc-dev make linux-headers gnupg libxslt-dev gd-dev geoip-dev wget
  
# 3.添加配置文件，目标路径以/结尾，docker会把它当作目录，不存在时，会自动创建
COPY nginx/nginx.conf /usr/local/nginx/conf/
COPY nginx_conf.d/*.conf /usr/local/nginx/conf.d/
COPY start.sh /


ENV TZ=Asia/Shanghai

# 4.更改启动脚本执行权限，设置时区为中国时间
RUN chmod u+x /start.sh  \
 && apk add --no-cache bash pcre-dev zlib-dev \
 \
 && apk add -U tzdata \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apk del tzdata && rm -rf /var/cache/apk/*

VOLUME ["/etc/fdfs", "/home/dfs", "/usr/local/nginx/conf.d"]
EXPOSE 22122 23000 8888

WORKDIR /

# 镜像启动
ENTRYPOINT ["/bin/bash","/start.sh"]