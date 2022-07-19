

# ansible 部署FATE集群双边场景示例

### 1 概述

​         本文介绍通过ansible 部署FATE集群的双边场景，分别是第二章介绍的部署exchange-guest(polling)和第三章介绍的部署host-guest(证书)。



### 2 部署exchange-guest(polling)

#### 2.1 概述

​       本章介绍通过ansible 部署FATE集群的双边场景之一： exchange-guest，并启用polling。 架构图如下：



![](images/guest-exchange.jpg)

#### 2.2 部署目标介绍

（1） Guest端

Party Id: 10000

| 角色           | IP          | 端口      | 介绍                                   |
| -------------- | ----------- | --------- | -------------------------------------- |
| rollsite       | 192.168.1.1 | 9370      | 跨站点或者说跨party通讯组件            |
| fate_flow      | 192.168.1.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| clustermanager | 192.168.1.1 | 4670      | cluster manager管理集群                |
| nodemanager     | 192.168.1.1 | 4671      | node manager管理每台机器资源           |
| fateboard      | 192.168.1.1 | 8080      | 联合学习过程可视化模块                 |
| mysql          | 192.168.1.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |

（2） exchange端

| 角色     | IP           | 端口 | 介绍                        |
| -------- | ------------ | ---- | --------------------------- |
| rollsite | 192.168.0.88 | 9370 | 跨站点或者说跨party通讯组件 |



#### 2.3 进入部署包根目录

   请按需使用合适的方式获取部署包，并解压，然后进入【部署包根目录】。具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.4.1和2.6.1等章节。


```
cd 【部署包根目录】
```



#### 2.4 配置

###### 2.4.1 初始化配置

- 步骤1：使用辅助脚本产生初始化配置

```
bash deploy/deploy.sh init -g="9999:192.168.1.1" -e="192.168.0.88"
```

- 步骤2： 修改配置

```
vim deploy/conf/setup.conf
```

```
env: prod
pname: fate
ssh_port: 22
deploy_user: app
deploy_group: apps
deploy_mode: deploy
modules:
  - mysql
  - eggroll
  - fate_flow
  - fateboard
roles:
  - host:10000
  - exchange:0
ssl_roles: []
polling:
  server_role: "exchange"
  client_role: "host"
host_ips: []
host_special_routes: []
guest_ips:
  - default:192.168.1.1
guest_special_routes: []
exchange_ips:
  - default:192.168.0.88
exchange_special_routes: []
default_engines: eggroll
```

启用了证书验证，则执行命令：

```
bash deploy/deploy.sh keys
```

- 步骤3：执行辅助脚本产生配置

```
bash deploy/deploy.sh render
```



###### 2.4.2 配置guest信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>>2.5.3一节，修改如下文件，默认可以不修改。

```
vi var_files/prod/fate_guest
```

内容如下：

```
guest:
  partyid: 9999
  rollsite:
    enable: True
    coordinator: fate
    ips:
    - 192.168.1.1
    port: 9370	---服务端口
    secure_port: 9371
    server_secure: False
    client_secure: False
    polling:
      enable: True
    route_tables:
    - id: default
      routes:
      - name: default
        ip: 192.168.0.88
        port: 9370
        is_secure: False
    - id: 10000
      routes:
      - name: default
        ip: 192.168.1.1
        port: 9370
        is_secure: false
      - name: fateflow
        ip: 192.168.1.1
        port: 9360
  clustermanager:
    enable: True
    ips:
    - 192.168.1.1
    port: 4670
    cores_per_node: 16
  nodemanager:
    enable: True
    ips:
    - 192.168.1.1
    port: 4671
  eggroll:
    dbname: "eggroll_meta"
    egg: 4
  fate_flow:
    enable: True
    ips:
    - 192.168.1.1
    grpcPort: 9360
    httpPort: 9380
    dbname: "fate_flow"
    proxy: rollsite
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll
  fateboard:
    enable: True
    ips:
    - 192.168.1.1
    port: 8080
    dbname: "fate_flow"
  mysql:
    enable: True
    type: inside
    ips:
    - 192.168.1.1
    port: 3306
    dbuser: "fate"
    dbpasswd: "fate_deV2999"
  zk:
    enable: False
    lists:
    - ip: 192.168.1.1
      port: 2181
    use_acl: false
    user: "fate"
    passwd: "fate"
  servings:
    ips:
    - 192.168.1.1
    port: 8000
```

###### 2.4.3 配置exchange信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。

```
vi var_files/prod/fate_exchange
```

内容如下：

```
exchange:
  rollsite:
    enable: True
    coordinator: fate
    ips:
    - 192.168.0.88
    port: 9370
    secure_port: 9371
    server_secure: False
    client_secure: False
    polling:
      enable: True
      ids:
      - 9999
  	route_tables:
  	- id: 9999
      routes:
      - name: default
        ip: 192.168.1.1
        port: 9370
        is_secure: False
```

#### 2.5 执行部署

- 部署所有服务

```
bash deploy/deploy.sh deploy
```

查看部署日志：`tailf logs/deploy-??.log`
​

#### 2.6 后置操作

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.6.8一节。




#### 2.7 服务验证与测试

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.7一节。



### 3 部署host-guest(证书)

#### 3.1 部署图

​      本章介绍通过ansible 部署FATE集群的双边场景之一： host-guest，并启用证书。 架构图如下：

![](images/host-guest.jpg)

#### 3.2 部署目标介绍

（1） Host端

Party Id: 10000

| 角色           | IP          | 端口      | 介绍                                   |
| -------------- | ----------- | --------- | -------------------------------------- |
| rollsite       | 192.168.0.1 | 9370      | 跨站点或者说跨party通讯组件            |
| fate_flow      | 192.168.0.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| clustermanager | 192.168.0.1 | 4670      | cluster manager管理集群                |
| nodemanager     | 192.168.0.1 | 4671      | node manager管理每台机器资源           |
| fateboard      | 192.168.0.1 | 8080      | 联合学习过程可视化模块                 |
| mysql          | 192.168.0.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |

（2） Guest端

Party Id: 9999

| 角色           | IP          | 端口      | 介绍                                   |
| -------------- | ----------- | --------- | -------------------------------------- |
| rollsite       | 192.168.1.1 | 9370      | 跨站点或者说跨party通讯组件            |
| fate_flow      | 192.168.1.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| clustermanager | 192.168.1.1 | 4670      | cluster manager管理集群                |
| nodemanager     | 192.168.1.1 | 4671      | node manager管理每台机器资源           |
| fateboard      | 192.168.1.1 | 8080      | 联合学习过程可视化模块                 |
| mysql          | 192.168.1.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |



#### 3.3 进入部署包根目录

 请按需使用合适的方式获取部署包，并解压，然后进入【部署包根目录】。具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.4.1和2.6.1等章节。


```
cd 【部署包根目录】
```



#### 3.4 配置

##### 3.4.1 初始化配置

- 步骤1：使用辅助脚本产生初始化配置

```
bash deploy/deploy.sh init -h="10000:192.168.0.1" -g="9999:192.168.1.1" -k="host|guest"
```

- 步骤2： 修改配置

```
vim deploy/conf/setup.conf
```

```
env: prod
pname: fate
ssh_port: 22
deploy_user: app
deploy_group: apps
deploy_mode: deploy
modules:
  - mysql
  - eggroll
  - fate_flow
  - fateboard
roles:
  - host:10000
  - guest:9999
ssl_roles:
  - host
  - guest
polling: {}
host_ips:
  - default:192.168.0.1
host_special_routes: []
guest_ips:
  - default:192.168.1.1
guest_special_routes: []
exchange_ips: []
exchange_special_routes: []
default_engines: eggroll
```

如果初始化启用了证书验证，则执行命令：

```
bash deploy/deploy.sh keys
```

- 步骤3：执行辅助脚本产生配置

```
bash deploy/deploy.sh render
```



##### 3.4.2 配置host信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。

```
vi var_files/prod/fate_host
```

内容如下：

```
host:
  partyid: 10000
  rollsite:
    enable: True
    coordinator: fate
    ips:
    - 192.168.0.1
    port: 9370	---服务端口
    secure_port: 9371
    server_secure: True
    client_secure: True
    polling:
      enable: False
    route_tables:
    - id: default
      routes:
      - name: default
        ip: 192.168.1.1
        port: 9371
        is_secure: True
    - id: 10000
      routes:
      - name: default
        ip: 192.168.0.1
        port: 9370
        is_secure: false
      - name: fateflow
        ip: 192.168.0.1
        port: 9360
  clustermanager:
    enable: True
    ips:
    - 192.168.0.1
    port: 4670
    cores_per_node: 16
  nodemanager:
    enable: True
    ips:
    - 192.168.0.1
    port: 4671
  eggroll:
    dbname: "eggroll_meta"
    egg: 4
  fate_flow:
    enable: True
    ips:
    - 192.168.0.1
    grpcPort: 9360
    httpPort: 9380
    dbname: "fate_flow"
    proxy: rollsite
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll
  fateboard:
    enable: True
    ips:
    - 192.168.0.1
    port: 8080
    dbname: "fate_flow"
  mysql:
    enable: True
    type: inside
    ips:
    - 192.168.0.1
    port: 3306
    dbuser: "fate"
    dbpasswd: "fate_deV2999"
  zk:
    enable: False
    lists:
    - ip: 192.168.0.1
      port: 2181
    use_acl: false
    user: "fate"
    passwd: "fate"
  servings:
    ips:
    - 192.168.0.1
    port: 8000
```

##### 3.4.3 配置guest信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。

```
vi var_files/prod/fate_guest
```

内容如下：

```
guest:
  partyid: 9999
  rollsite:
    enable: True
    coordinator: fate
    ips:
    - 192.168.1.1
    port: 9370	---服务端口
    secure_port: 9371
    server_secure: True
    client_secure: True
    polling:
      enable: False
    route_tables:
    - id: default
      routes:
      - name: default
        ip: 192.168.0.1
        port: 9371
        is_secure: True
    - id: 9999
      routes:
      - name: default
        ip: 192.168.1.1
        port: 9370
        is_secure: false
      - name: fateflow
        ip: 192.168.1.1
        port: 9360
  clustermanager:
    enable: True
    ips:
    - 192.168.1.1
    port: 4670
    cores_per_node: 16
  nodemanager:
    enable: True
    ips:
    - 192.168.1.1
    port: 4671
  eggroll:
    dbname: "eggroll_meta"
    egg: 4
  fate_flow:
    enable: True
    ips:
    - 192.168.1.1
    grpcPort: 9360
    httpPort: 9380
    dbname: "fate_flow"
    proxy: rollsite
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll
  fateboard:
    enable: True
    ips:
    - 192.168.1.1
    port: 8080
    dbname: "fate_flow"
  mysql:
    enable: True
    type: inside
    ips:
    - 192.168.1.1
    port: 3306
    dbuser: "fate"
    dbpasswd: "fate_deV2999"
  zk:
    enable: False
    lists:
    - ip: 192.168.1.1
      port: 2181
    use_acl: false
    user: "fate"
    passwd: "fate"
  servings:
    ips:
    - 192.168.1.1
    port: 8000
```

#### 3.5 执行部署

- 部署所有服务

```
bash deploy/deploy.sh deploy
```

查看部署日志：`tailf logs/deploy-??.log`




#### 3.6 后置操作

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.6.8一节。




#### 3.7 服务验证与测试

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.7一节。



### 4 部署host-guest(spark)

#### 4.1 部署图

​      本章介绍通过ansible 部署FATE集群的双边场景之一： host-guest，并使用spark。 架构图如下：

![](images/host-guest-spark.jpg)

#### 4.2 部署目标介绍

（1） Host端

Party Id: 10000

| 角色      | IP          | 端口      | 介绍                                   |
| --------- | ----------- | --------- | -------------------------------------- |
| fate_flow | 192.168.0.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| fateboard | 192.168.0.1 | 8080      | 联合学习过程可视化模块                 |
| mysql     | 192.168.0.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |

（2） Guest端

Party Id: 9999

| 角色      | IP          | 端口      | 介绍                                   |
| --------- | ----------- | --------- | -------------------------------------- |
| fate_flow | 192.168.1.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| fateboard | 192.168.1.1 | 8080      | 联合学习过程可视化模块                 |
| mysql     | 192.168.1.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |



#### 4.3 进入部署包根目录

 请按需使用合适的方式获取部署包，并解压，然后进入【部署包根目录】。具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.4.1和2.6.1等章节。


```
cd 【部署包根目录】
```



#### 4.4 配置

##### 4.4.1 初始化配置

- 步骤1：使用辅助脚本产生初始化配置

```
bash deploy/deploy.sh init -h="10000:192.168.0.1" -g="9999:192.168.1.1" -n=spark
```

- 步骤2： 修改配置，具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.2.5等章节。

```
vim deploy/conf/setup.conf
```

```
env: prod
pname: fate
ssh_port: 22
deploy_user: app
deploy_group: apps
deploy_mode: deploy
modules:
  - mysql
  - fate_flow
  - fateboard
roles:
  - host:10000
  - guest:9999
ssl_roles: []
host_ips:
  - default:192.168.0.1
host_special_routes: []
guest_ips:
  - default:192.168.1.1
guest_special_routes: []
default_engines: spark

//以下信息按实际情况填写，包括计算引擎、存储引擎和mq
#host spark configuration information
#compute_engine: spark
host_compute_engine: spark
host_spark_home: ""
host_hadoop_home: ""
#storage_engine: hive or hdfs or localfs
host_storage_engine: hive
host_hive_ips: "192.168.0.1"
host_hdfs_addr: ""
#mq_engine: rabbitmq or pulsar
host_mq_engine: rabbitmq
host_rabbitmq_ips: "192.168.0.1"
host_pulsar_ips: ""
#proxy
host_nginx_ips: "192.168.0.1"

#
#guest spark configuration information
#compute_engine: spark
guest_compute_engine: spark
guest_spark_home: ""
guest_hadoop_home: ""
#storage_engine: hive or hdfs or localfs
guest_storage_engine: hive
guest_hive_ips: "192.168.1.1"
guest_hdfs_addr: ""
#mq_engine: rabbitmq or pulsar
guest_mq_engine: rabbitmq
guest_rabbitmq_ips: "192.168.1.1"
guest_pulsar_ips: ""
#proxy
guest_nginx_ips: "192.168.1.1"
```

- 步骤3：执行辅助脚本产生配置

```
bash deploy/deploy.sh render
```



##### 4.4.2 配置host信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。

```
vi var_files/prod/fate_host
```

内容如下：

```
host:
  partyid: 10000
  fate_flow:
    enable: True
    ips:
    - 192.168.0.1
    grpcPort: 9360
    httpPort: 9380
    dbname: "fate_flow"
    proxy: rollsite
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: spark
    federation: rabbitmq
    storage: hdfs
  fateboard:
    enable: True
    ips:
    - 192.168.0.1
    port: 8080
    dbname: "fate_flow"
  mysql:
    enable: True
    type: inside
    ips:
    - 192.168.0.1
    port: 3306
    dbuser: "fate"
    dbpasswd: "fate_deV2999"
  zk:
    enable: False
    lists:
    - ip: 192.168.0.1
      port: 2181
    use_acl: false
    user: "fate"
    passwd: "fate"
  servings:
    ips:
    - 192.168.0.1
    port: 8000
  spark:			---开启spark信息
    enable: True
    home:
    hadoop_home:
    cores_per_node: 20
    nodes: 2
  hive:
    enable: True
    host: 192.168.0.1
    port: 10000
    auth:
    configuration:
    kerberos_service_name:
    username:
    password:
  hdfs:
    enable: False
    name_node: hdfs://fate-cluster
    path_prefix:
  rabbitmq:			---rabbitmq部署信息
    enable: True
    host: 192.168.0.1
    mng_port: 12345
    port: 5672
    user: fate
    password: fate
    route_table:
      - id: 10000
        routes:
          - ip: 192.168.0.1
            port: 5672
  pulsar:
    enable: False
    host: 192.168.0.1
    port: 6650
    mng_port: 8080
    topic_ttl: 5
    route_table:
      - id: 10000
        routes:
          - ip: 192.168.0.1
            port: 6650
            sslPort: 6651
            proxy: ""
  nginx:
    enable: True
    host: 192.168.0.1
    http_port: 9300		//按实际修改端口
    grpc_port: 9310
```

##### 4.4.3 配置guest信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。

```
vi var_files/prod/fate_guest
```

内容如下：

```
guest:
  partyid: 9999
  fate_flow:
    enable: True
    ips:
    - 192.168.1.1
    grpcPort: 9360
    httpPort: 9380
    dbname: "fate_flow"
    proxy: rollsite
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: spark
    federation: rabbitmq
    storage: hdfs
  fateboard:
    enable: True
    ips:
    - 192.168.1.1
    port: 8080
    dbname: "fate_flow"
  mysql:
    enable: True
    type: inside
    ips:
    - 192.168.1.1
    port: 3306
    dbuser: "fate"
    dbpasswd: "fate_deV2999"
  zk:
    enable: False
    lists:
    - ip: 192.168.1.1
      port: 2181
    use_acl: false
    user: "fate"
    passwd: "fate"
  servings:
    ips:
    - 192.168.1.1
    port: 8000
  spark:			---开启spark信息
    enable: True
    home:
    hadoop_home:
    cores_per_node: 20
    nodes: 2
  hive:
    enable: True
    host: 192.168.1.1
    port: 10000
    auth:
    configuration:
    kerberos_service_name:
    username:
    password:
  hdfs:
    enable: False
    name_node: hdfs://fate-cluster
    path_prefix:
  rabbitmq:			---rabbitmq部署信息
    enable: True
    host: 192.168.1.1
    mng_port: 12345
    port: 5672
    user: fate
    password: fate
    route_table:
      - id: 9999
        routes:
          - ip: 192.168.1.1
            port: 5672
  pulsar:
    enable: False
    host: 192.168.0.1
    port: 6650
    mng_port: 8080
    topic_ttl: 5
    route_table:
      - id: 9999
        routes:
          - ip: 192.168.0.1
            port: 6650
            sslPort: 6651
            proxy: ""
  nginx:
    enable: True
    host: 192.168.1.1
    http_port: 9300		//按实际修改端口
    grpc_port: 9310
```

#### 4.5 执行部署

- 部署所有服务

```
bash deploy/deploy.sh deploy
```

查看部署日志：`tailf logs/deploy-??.log`




#### 4.6 后置操作

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.6.8一节。




#### 4.7 服务验证与测试

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.7一节。





