## 说明
[registry deploying doc](https://docs.docker.com/registry/deploying/)

运行参数说明
```
--privileged=true centos7中的安全模块selinux把权限禁止了，加上这行是给容器增加执行权限
-v /data/docker-registry:/var/lib/registry 把主机的/data/docker-registry 目录挂载到registry容器的/var/lib/registry目录下，假如有删除容器操作，我们的镜像也不会被删除
```

如果使用自定义配置挂载如下yml文件，然后在运行registry的时候增加挂载，挂载到容器的`/etc/distribution/config.yml`文件中，具体其他[配置](https://distribution.github.io/distribution/about/configuration/)
也可以通过环境变量覆盖配置，查看配置文档，和上面的设置REGISTRY_AUTH_HTPASSWD_PATH类似
```yml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

## Push镜像到私服
```
//  创建 tag
docker tag openzipkin/zipkin docker-registry.wangchao.im/zipkin:0.1.0
// push
docker push docker-registry.wangchao.im/zipkin:0.1.0
```

## Docker Login
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

## Https
在生产环境，建议为 Registry 配置 HTTPS：
如果是测试环境，可以使用自签名证书
```bash
# 生成自签名证书
openssl req -newkey rsa:4096 -nodes -sha256 -keyout registry.key \
  -x509 -days 365 -out registry.crt \
  -subj "/CN=192.168.0.170"

# 启动带 TLS 的 Registry
docker run -d -p 5000:5000 \
  -v $(pwd)/registry.crt:/certs/registry.crt \
  -v $(pwd)/registry.key:/certs/registry.key \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
  registry:2
```