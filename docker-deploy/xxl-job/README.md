# XXL JOB

## 配置说明
docker部署，如果需要修改参数或者配置，使用环境变量配置
 * 如需自定义 “项目配置文件” 中配置项，比如 mysql 配置，可通过 "-e PARAMS" 指定，参数格式: -e PARAMS="--key=value --key2=value2"；（配置项参考文件：/xxl-job/xxl-job-admin/src/main/resources/application.properties）
 * 如需自定义 “JVM内存参数”，可通过 "-e JAVA_OPTS" 指定，参数格式: -e JAVA_OPTS="-Xmx512m"
 * 如需自定义 “日志文件目录”，可通过 "-e LOG_HOME" 指定，参数格式: -e LOG_HOME=/data/applogs