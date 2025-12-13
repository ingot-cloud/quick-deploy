
# ES 配置说明

## 配置账号密码
1. 进入容器
```
#进入es容器
docker exec -it es /bin/bash
```

2. 生成CA
```
# 生成ca
./bin/elasticsearch-certutil ca
```

3. 生成证书
```
# 再生成cert
./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
```
证书生成在/usr/share/elasticsearch/目录下

4. 拷贝容器中的证书
```
# 拷贝容器证书
docker cp es:/usr/share/elasticsearch/elastic-certificates.p12 ./
 
# 授权证书
chmod 777 elastic-certificates.p12
```

5. 配置文件
elasticsearch.yml
```
network.host: 0.0.0.0
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.type: PKCS12
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/elastic-certificates.p12
xpack.security.transport.ssl.truststore.type: PKCS12
 
xpack.security.audit.enabled: true
```

6. 挂载文件
挂载证书和配置文件，挂载文件后，重新run镜像

7. 设置密码
```
# 进入es容器
docker exec -it es /bin/bash
 
# 设置密码（账号默认为 elastic）
./bin/elasticsearch-setup-passwords interactive
```


## 报错相关
如果报错updatejava.net.UnknownHostException: geoip.elastic.co
可以在配置文件中加入
```
ingest.geoip.downloader.enabled: false
```