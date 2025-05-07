FROM nginx
VOLUME ["/tmp","/etc/nginx/conf.d"]
ENV LANG en_US.UTF-8
COPY ./proxy.conf /etc/nginx/conf.d/
EXPOSE 3000
EXPOSE 443