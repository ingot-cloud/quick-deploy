## 说明
[registry deploying doc](https://docs.docker.com/registry/deploying/)

运行参数说明
```
--privileged=true centos7中的安全模块selinux把权限禁止了，加上这行是给容器增加执行权限
-v /data/docker-registry:/var/lib/registry 把主机的/data/docker-registry 目录挂载到registry容器的/var/lib/registry目录下，假如有删除容器操作，我们的镜像也不会被删除
```

如果使用自定义配置挂载如下yml文件，然后在运行registry的时候增加挂载，挂载到容器的`/etc/docker/registry/config.yml`文件中，具体其他[配置](https://docs.docker.com/registry/configuration/)
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
```
# 创建存储鉴权密码文件目录
mkdir -p /usr/local/registry/auth
# 安装 httpd
yum install -y httpd
# 创建用户和密码
htpasswd -Bbn admin 111111 > /usr/local/registry/auth/htpasswd

运行时候，注意增加脚本中auth相关的挂载和环境变量即可
```
