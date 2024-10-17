## 说明

挂载volumes如果遇到权限问题
```
 mkdir: cannot create directory '/bitnami/kafka/config': Permission denied
```
需要给目录增加权限
```
sudo chown -R 1001:1001 kafka
```

相关文献[stackoverflow](https://stackoverflow.com/questions/73860963/mkdir-cannot-create-directory-bitnami-kafka-config-permission-denied)和[github issues](https://github.com/bitnami/containers/issues/41422)