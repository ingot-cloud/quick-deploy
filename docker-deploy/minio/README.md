# 说明

社区版从`RELEASE.2025-04-22T22-12-26Z`版本后，web控制台变成了阉割版本，运维只能使用`mc`进行操作，`mc`操作如下：

| 原后台功能（旧版 UI）                    | 新版替代方式                                         | CLI/脚本示例                                                                                              |
| ------------------------------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **创建 Bucket**                   | `mc mb` 命令                                     | `bash mc alias set local http://127.0.0.1:9000 minioadmin minioadmin  # 配置别名<br>mc mb local/mybucket` |
| **删除 Bucket**                   | `mc rb` 命令                                     | `bash mc rb --force local/mybucket`                                                                   |
| **Bucket 权限设置（public/private）** | `mc anonymous set`                             | `bash mc anonymous set public local/mybucket`                                                         |
| **Bucket 版本控制开关**               | `mc version`                                   | `bash mc version enable local/mybucket`                                                               |
| **Bucket 生命周期规则**               | `mc ilm` 命令                                    | `bash mc ilm add local/mybucket --expiry-days 30`                                                     |
| **Bucket 配额限制**                 | `mc quota` 命令                                  | `bash mc quota set local/mybucket --size 10GB`                                                        |
| **用户管理（新增/删除）**                 | `mc admin user`                                | `bash mc admin user add local testuser testpass123`                                                   |
| **访问策略绑定用户**                    | `mc admin policy`                              | `bash mc admin policy set local readwrite user=testuser`                                              |
| **查看节点状态**                      | `mc admin info`                                | `bash mc admin info local`                                                                            |
| **查看磁盘健康**                      | `mc admin heal`                                | `bash mc admin heal local`                                                                            |
| **分布式节点修复**                     | `mc admin heal`（全量或指定桶）                        | `bash mc admin heal local/mybucket`                                                                   |
| **查看服务日志**                      | `mc admin trace`                               | `bash mc admin trace local`                                                                           |
| **监控指标（原 UI 图表）**               | `Prometheus + Grafana` 或 `mc admin prometheus` | `bash mc admin prometheus generate local`                                                             |
| **带宽限制**                        | `mc admin config` 修改参数                         | `bash mc admin config set local api requests_max=100`                                                 |
| **策略管理（Policy CRUD）**           | `mc admin policy`                              | `bash mc admin policy add local readonly readonly.json`                                               |


如果需要继续使用之前的版本，可以拉取`minio/minio:RELEASE.2025-04-22T22-12-26Z`, 也可以拉取私有仓库`docker-registry.ingotcloud.top/minio/minio:RELEASE.2025-04-22T22-12-26Z`