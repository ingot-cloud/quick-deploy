## 说明

### 1. 部署kafka
执行运行脚本：
```shell
./run.sh
```

### 2. 创建topic
```shell
/opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server kafka:29092 \
  --create \
  --topic test.tp.v1 \
  --partitions 3 \
  --replication-factor 1 \
  --config compression.type=lz4 \
  --config retention.ms=259200000 \
  --config segment.bytes=1073741824 \
  --config max.message.bytes=20000000
```
 * partitions=3 → 适度分区，保证顺序性由 key 控制，同时提高吞吐
 * replication-factor=1 → 单机只能1
 * compression.type=lz4 → 高速压缩，提高磁盘利用率
 * segment.bytes=1GB → 日志切割方便管理
 * retention.ms=3天 → 满足 20GB/day 保留策略
 * max.message.bytes=20MB → 单条最大消息
