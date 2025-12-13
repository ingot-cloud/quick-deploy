# nginx 代理

## 配置
镜像提供了挂载目录`/etc/nginx/conf.d`

 * 如果只是修改域名对应代理地址，那么只需要挂载`/etc/nginx/conf.d/proxy.conf`即可，也就是修改proxy.conf中的proxy_pass即可。
