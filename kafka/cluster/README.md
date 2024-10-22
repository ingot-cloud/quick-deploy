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


1. 配置外网访问host，目前默认是配置ingot-localhost，可以把改host配置为本机外网ip。相关配置为KAFKA_CFG_ADVERTISED_LISTENERS
2. KAFKA_BROKER_ID 必须与 KAFKA_CFG_NODE_ID 保持一致
3. KAFKA_KRAFT_CLUSTER_ID 可以使用菜鸟工具生成一个 22 位随机字符
4. 以上两个部署 kafka 的 yaml 文件中，都设置了 KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=false，表示不自动创建 topic，必须手动创建，比如可以通过 kafka-console-ui 的 Topic 页签来操作