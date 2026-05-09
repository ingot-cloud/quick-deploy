FROM docker-registry.ingotcloud.top/nginx:1.28.3
VOLUME ["/tmp","/etc/nginx/conf.d"]
ENV LANG en_US.UTF-8
COPY ./proxy.conf /etc/nginx/conf.d/
EXPOSE 3000
EXPOSE 443