# Seafile

## 部署

### 整体Nginx配置
```nginx
server {
    listen       80;
    server_name  localhost;
    
    client_max_body_size 0;

    location / {
        proxy_pass http://127.0.0.1:8088;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 36000s;
    }

    location /sdoc-server/ {
        proxy_pass http://127.0.0.1:7070/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /socket.io {
        proxy_pass http://127.0.0.1:7070;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /onlyoffice/ {
        proxy_pass http://127.0.0.1:6233/;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /onlyoffice/editor-callback/ {
        proxy_pass http://127.0.0.1:8088/onlyoffice/editor-callback/;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        client_max_body_size 0;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }

    location /onlyofficeds/ {
        proxy_pass http://127.0.0.1:6233/;
        proxy_http_version 1.1;

        client_max_body_size 100M;
        proxy_read_timeout 3600s;
        proxy_connect_timeout 3600s;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host/onlyofficeds;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### OnlyOffice
onlyoffice.yml相关配置可以和seafile-server.yml合并到一起
```shell
docker compose up -d onlyoffice
```
启动后检查
```bash
curl http://127.0.0.1:6233/welcome/
```

修改Seafile配置文件
```bash
docker exec -it seafile bash
vi /opt/seafile/conf/seahub_settings.py
```
添加以下内容(注意域名是nginx里面配置的，一般和seafile中配置的相同)：
```python
SERVICE_URL = 'http://这里是env中SEAFILE_SERVER_HOSTNAME的值'
FILE_SERVER_ROOT = 'http://这里是env中SEAFILE_SERVER_HOSTNAME的值/seafhttp'

ENABLE_ONLYOFFICE = True

ONLYOFFICE_APIJS_URL = 'http://这里是env中SEAFILE_SERVER_HOSTNAME的值/onlyofficeds/web-apps/apps/api/documents/api.js'

ONLYOFFICE_JWT_SECRET = '改成和 docker-compose 里 JWT_SECRET 一样的密钥'

ONLYOFFICE_FILE_EXTENSION = (
    'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx',
    'odt', 'fodt', 'odp', 'fodp', 'ods', 'fods',
    'ppsx', 'pps', 'csv'
)

ONLYOFFICE_EDIT_FILE_EXTENSION = (
    'docx', 'pptx', 'xlsx', 'csv'
)

OFFICE_PREVIEW_MAX_SIZE = 30 * 1024 * 1024
```

重启服务
```bash
docker compose restart seafile
```

注意onlyoffice中的host配置，主要是让onlyoffice可以访问到seafile
```yml
    extra_hosts:
      - "这里是env中SEAFILE_SERVER_HOSTNAME的值:这里是部署服务器的ip地址"
```