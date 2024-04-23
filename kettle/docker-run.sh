#!/usr/bin/env bash

currentPath=`cd $(dirname $0);pwd -P`

mkdir -p /ingot-data/docker/volumes/kettle/.kettle
cp ${currentPath}/mysql-connector-java-5.1.49.jar /ingot-data/docker/volumes/kettle/mysql-connector-java-5.1.49.jar

docker run --name webspoon -d -p 9080:8080 \
-v /ingot-data/docker/volumes/kettle/mysql-connector-java-5.1.49.jar:/usr/local/tomcat/webapps/spoon/WEB-INF/lib/mysql-connector-java-5.1.49.jar \
-v /ingot-data/docker/volumes/kettle/.kettle:/home/tomcat/.kettle \
hiromuhota/webspoon