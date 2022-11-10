## 说明
[doc](https://docs.portainer.io/v/be-2.10/start/install/server/docker/linux)

portainer-agent, 注意如果设置AGENT_SECRET，那么portainer在启动的时候也需要设置对应的秘钥
```
#!/usr/bin/env bash

docker run -d --name portainer_agent \
 --network ingot-net \
 --restart=always \
 -e AGENT_SECRET=123456 \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v /var/lib/docker/volumes:/var/lib/docker/volumes \
 portainer/agent:latest
```

portainer商业版，需要申请License，[官网](https://www.portainer.io/)
```
#!/usr/bin/env bash


# 说明 https://docs.portainer.io/v/be-2.10/start/install/server/docker/linux


VIRTUAL_HOST=portainer.wangchao.im
VIRTUAL_PORT=9000

docker run -d --name portainer-ee \
 --network ingot-net \
 --restart always \
 -e VIRTUAL_HOST=${VIRTUAL_HOST} \
 -e VIRTUAL_PORT=${VIRTUAL_PORT} \
 -e LETSENCRYPT_HOST=${VIRTUAL_HOST} \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v portainer_data:/data \
 portainer/portainer-ee:latest
```
