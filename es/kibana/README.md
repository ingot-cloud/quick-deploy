## 

###

1. 启动kibana
```
docker run --name kibana \
 -d --restart=always \
 --network ingot-net --ip 172.88.0.130  \
 -p 5601:5601 \
 -e "ELASTICSEARCH_HOSTS=http://es01-test:9200" \
 docker.elastic.co/kibana/kibana:7.17.21
```

2. 复制config文件
```
docker cp kibana:/usr/share/kibana/config /ingot-data/docker/volumes/kibana/
```

3. 修改kibana.yml
kibana.yml
```
server.host: "0.0.0.0"
server.shutdownTimeout: "5s"
# 修改为对应host地址
elasticsearch.hosts: [ "http://es01-test:9200" ]
monitoring.ui.container.elasticsearch.enabled: true
i18n.locale: "zh-CN"
elasticsearch.username: "elastic"
elasticsearch.password: "你的es密码"
```

4. 挂载重新run
```
docker run --name kibana \
 -d --restart=always \
 --network ingot-net --ip 172.88.0.130  \
 -p 5601:5601 \
 -v /ingot-data/docker/volumes/kibana/config:/usr/share/kibana/config \
 docker.elastic.co/kibana/kibana:7.17.21
```