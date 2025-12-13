## 说明
[nginx-proxy地址](https://github.com/nginx-proxy/nginx-proxy)

执行`docker run`时增加如下环境变量
 * 域名: `VIRTUAL_HOST`
 * docker中服务的端口: `VIRTUAL_PORT`
 * HTTPS域名: `LETSENCRYPT_HOST`
```
-e VIRTUAL_HOST=${VIRTUAL_HOST} \
-e VIRTUAL_PORT=${VIRTUAL_PORT} \
-e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
```
注意network需要和nginx-proxy保持一致，如上network为ingot-net
