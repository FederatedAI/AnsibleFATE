# ansible 部署FATE集群手册

<!-- TOC -->

- [1.1 FATE简介](#11-fate简介)
- [2.1 环境依赖](#21-环境依赖)
- [2.2 依赖条件和前置操作](#22-依赖条件和前置操作)
- [2.3 组件信息](#23-组件信息)
- [2.4 基本概念与原理](#24-基本概念与原理)
    - [2.4.1 版本和部署包形态](#241-版本和部署包形态)
    - [2.4.2 部署流程](#242-部署流程)
    - [2.4.3 部署形态](#243-部署形态)
    - [2.4.4 部署角色、后端引擎和模块](#244-部署角色后端引擎和模块)
    - [2.4.5 配置模块组件](#245-配置模块组件)
    - [2.4.6 部署支持polling](#246-部署支持polling)
    - [2.4.7 路由支持](#247-路由支持)
        - [2.4.7.1 配置路由的参数](#2471-配置路由的参数)
        - [**2.4.7.2 路由逻辑**](#2472-路由逻辑)
        - [2.4.7.3 路由地址](#2473-路由地址)
    - [2.4.8 证书支持](#248-证书支持)
    - [2.4.9 配置Spark参数](#249-配置spark参数)
- [2.5 辅助脚本和配置文件](#25-辅助脚本和配置文件)
    - [2.5.1 下载脚本和下载配置文件](#251-下载脚本和下载配置文件)
        - [2.5.1.1 下载脚本的使用](#2511-下载脚本的使用)
        - [2.5.1.2 下载配置文件](#2512-下载配置文件)
    - [2.5.2 部署辅助脚本和部署配置文件](#252-部署辅助脚本和部署配置文件)
        - [2.5.2.1 部署辅助脚本使用指引](#2521-部署辅助脚本使用指引)
        - [2.5.2.2 使用部署辅助脚本进行初始化](#2522-使用部署辅助脚本进行初始化)
        - [2.5.2.3 使用部署辅助脚本生成证书](#2523-使用部署辅助脚本生成证书)
        - [2.5.2.4 使用部署辅助脚本进行部署或卸载](#2524-使用部署辅助脚本进行部署或卸载)
        - [2.5.2.5 配置文件场景示例](#2525-配置文件场景示例)
    - [2.5.3 ansible配置文件](#253-ansible配置文件)
        - [2.5.3.1 配置base信息](#2531-配置base信息)
        - [2.5.3.2 配置fate基础信息](#2532-配置fate基础信息)
        - [2.5.3.3 配置Exchange信息](#2533-配置exchange信息)
        - [2.5.3.4  配置Host信息](#2534--配置host信息)
        - [2.5.3.5 配置Guest信息](#2535-配置guest信息)
        - [2.5.3.6 配置任务列表](#2536-配置任务列表)
        - [2.5.3.7 配置主机列表](#2537-配置主机列表)
- [2.6 部署流程](#26-部署流程)
    - [2.6.1 下载](#261-下载)
        - [2.6.1.1 下载离线包](#2611-下载离线包)
        - [2.6.1.2下载非离线包](#2612下载非离线包)
        - [2.6.1.3 按需下载模块的资源包](#2613-按需下载模块的资源包)
        - [2.6.1.4 按需自编译模块的资源包](#2614-按需自编译模块的资源包)
    - [2.6.2 使用初始化脚本生成部署配置文件](#262-使用初始化脚本生成部署配置文件)
    - [2.6.3 调整参数并生成ansible配置文件](#263-调整参数并生成ansible配置文件)
    - [2.6.4 执行ping测试(可选)](#264-执行ping测试可选)
    - [2.6.5 生成证书(可选)](#265-生成证书可选)
    - [2.6.6 执行部署（按需）](#266-执行部署按需)
    - [2.6.7 检查服务](#267-检查服务)
    - [2.6.8 执行部署后置操作](#268-执行部署后置操作)
    - [2.6.9 执行测试](#269-执行测试)
- [2.7 服务验证](#27-服务验证)
    - [2.7.1 服务进程验证](#271-服务进程验证)
    - [2.7.2 Toy_example部署验证](#272-toy_example部署验证)
        - [2.7.2.1 单边测试](#2721-单边测试)
        - [2.7.2.2 双边测试](#2722-双边测试)
    - [2.7.3 最小化测试](#273-最小化测试)
        - [**2.7.3.1 上传预设数据**](#2731-上传预设数据)
        - [**2.7.3.2 快速模式**](#2732-快速模式)
        - [**2.7.3.3 正常模式**](#2733-正常模式)
- [2.8 服务运维](#28-服务运维)
- [3.1 使用自签证书](#31-使用自签证书)
- [3.2 单边部署使用证书场景](#32-单边部署使用证书场景)
- [3.3 mysql使用外部数据库](#33-mysql使用外部数据库)

<!-- /TOC -->



### 1概述

#### 1.1 FATE简介

FATE (Federated AI Technology Enabler) 是微众银行AI部门发起的开源项目，为联邦学习生态系统提供了可靠的安全计算框架。FATE项目使用多方安全计算 (MPC) 以及同态加密 (HE) 技术构建底层安全计算协议，以此支持不同种类的机器学习的安全计算，包括逻辑回归、基于树的算法、深度学习和迁移学习等。

FATE官方网站：https://fate.fedai.org/



本文将介绍使用通过Ansible进行部署FATE集群。我们提供了辅助脚本，优化部署配置的过程，有助于用户快速完成部署操作。部署是一件简单的事。。




### 2 部署手册
#### 2.1 环境依赖

| 名称     | 说明                             |
| -------- | -------------------------------- |
| 系统     | Centos 7.6                       |
| 开发语言 | Python 3.6.5、Java 1.8           |
| 软件组件 | fate  eggroll  fateboard   mysql |



#### 2.2 依赖条件和前置操作

假定是以普通账号（app账号）进行部署，部署Base模块则需要root权限(假定app账号具有免输入密码的sudo权限）。部署的目标为: ${pbase}/fate目录下。这里假定：

- pbase： /data/projects
- tbase:  /data/temp
- lbase: /data/logs
- host_id: 10000
- guest_id: 9999

 前置操作请参考： <<[部署fate集群的前置操作](action_before_deploy_fate_cluster.md)>> 一文。



#### 2.3 组件信息

| 角色           | 端口      | 日志目录                   | 介绍                                   |
| -------------- | --------- | -------------------------- | -------------------------------------- |
| rollsite       | 9370      | /data/logs/fate/eggroll/   | 跨站点或者说跨party通讯组件            |
| fate_flow      | 9360;9380 | /data/logs/fate/fateflow/  | 联合学习任务流水线管理模块             |
| clustermanager | 4670      | /data/logs/fate/eggroll/   | cluster manager管理集群                |
| nodemanager     | 4671      | /data/logs/fate/eggroll/   | node manager管理每台机器资源           |
| fateboard      | 8080      | /data/logs/fate/fateboard/ | 联合学习过程可视化模块                 |
| mysql          | 3306      | /data/logs/mysql/          | 数据存储，clustermanager和fateflow依赖 |



#### 2.4 基本概念与原理

##### 2.4.1 版本和部署包形态

- 版本：大于等于1.7.0

- 离线包： 可以直接进行部署的包。
   - 部署包名称：`AnsibleFATE_${version}_release-offline.tar.gz`
   - 部署包根目录名称：`AnsibleFATE-${version}-release-offline`
- 在线包： 部署的包，但不包括模块的资源包，不能直接进行部署。 可通过下载资源包（参考2.6.1.3一节），组装成离线包。

  - 部署包名称： `AnsibleFATE_${version}_release-online.tar.gz`
  - 部署包根目录名称：   `AnsibleFATE-${version}-release-online`

##### 2.4.2 部署流程

- 下载部署包

- 进行部署

​

##### 2.4.3 部署形态

- 安装： 只安装软件

- 更新配置： 只更新配置

- 部署： 安装软件和更新配置

- 删除： 删除软件和配置


##### 2.4.4 部署角色、后端引擎和模块

| 后端引擎        | 可选部署角色          | 可选部署模块                          |
| --------------- | --------------------- | ------------------------------------- |
| standalone      | host、guest、exchange | mysql、eggroll、fate_flow、fateboard  |
| eggroll（默认） | host、guest、exchange | mysql、eggroll、fate_flow、fateboard  |
| spark           | host、guest           | mysql、fate_flow、fateboard、rabbitmq |



##### 2.4.5 配置模块组件

- 简单模式

  "default:192.168.0.1"

- 详细定制模式

  - host/guest端

  "default:192.168.0.1" "rollsite:192.168.0.1" "nodemanager:192.168.0.1|192.168.0.2" "clustermanager:192.168.0.1" "fate_flow:192.168.0.1" "fateboard:192.168.0.1"

  - exchange端

    "rollsite:192.168.0.3|192.168.0.4"

- 组件配置逻辑

  - 非exchange情景，必须设置default值

  - nodemanager按需设置一个或多个IP

  - exchange的rollsite按需设置一个或多个IP

  - 非exchange的rollsite只可以设置1个ip

  - 其他组件只可以设置一个ip

  - 当没有设置的组件，会使用default值。


##### 2.4.6 部署支持polling

​         服务端必须是exchange

​         本节内容适用于后端引擎为非spark的场景。



##### 2.4.7 路由支持

​        本节内容适用于后端引擎为非spark的场景。

###### 2.4.7.1 配置路由的参数

​     包括默认路由参数和额外路由参数。

###### **2.4.7.2 路由逻辑**

- 部署三方，host和guest的默认路由是exchange。 exchange不设置默认路由。
- 部署两方（host和guest），互为默认路由。
- 部署两方（一方为exchange），非exchange方默认路由为exchange。
- 可以通过额外路由设置本端的默认路由。本设置会覆盖上述默认路由。
- 部署一方如果需要设置默认路由，可通过设置额外路由来实现，可以支持证书方式
- exchange如果需要设置默认路由，可通过设置额外路由来实现，可以支持证书方式
- 当exchange需要部署多个机器时，必须通过添加额外路由来设置一个默认路由。

###### 2.4.7.3 路由地址

​          支持ip也支持域名。



##### 2.4.8 证书支持

​       本节内容目前仅适用于后端引擎为非spark的场景。

- 目前证书只支持两方

- 脚本默认生成的所有证书使用相同ca

- 脚本也支持生成的证书使用不同的ca（执行命令需要增加参数）

- 用户使用另外自签证书，需要在使用证书的方式部署完成后，再手工替换，并重启服务。

- 部署单边的情况，也支持配置证书。  用脚本只产生一方的证书。然后服务端和客户端的设置使用这个证书。  部署完成之后，用户手工按需替换其他证书。


##### 2.4.9 配置Spark参数

- 支持spark、plusar/rabbitmq、hdfs/hive等应用场景
- spark只有host&guest场景适用



#### 2.5 辅助脚本和配置文件

##### 2.5.2 部署辅助脚本和部署配置文件

部署辅助脚本：   deploy/deploy.sh

部署配置文件：   deploy/conf/setup.conf

ansible配置文件： var_files/prod/*

###### 2.5.2.1 部署辅助脚本使用指引

```
bash deploy/deploy.sh --help
Usage: deploy/deploy.sh init|render|deploy|install|config|uninstall|keys|help args

bash deploy/deploy.sh init --help
Usage: deploy/deploy.sh -h|-g|-e|-m|-k
     args:
         -h=ip
         -g=ip
         -e=ip
         -m=install or uninstall
         -k=both roles of keys(eg: host|guest)
         -n=standalone or eggroll or spark（default： eggroll）
```



###### 2.5.2.2 使用部署辅助脚本进行初始化

- 生成部署配置文件

```
bash deploy/deploy.sh  init [-g|-h|-e|-m|-k|-n]
```

参数说明：

​        -g：表示部署guest，可不填参数值；格式“partyid:ip”，使用示例： -g="9999:192.168.1.1" 或  -g

​        -h：表示部署host，可不填参数值；格式“partyid:ip”，使用示例:  -h="10000:192.168.0.1"  或  -h

​        -e：表示部署exchange，可不填参数值；格式“ip or ip列表（用|分隔）”，使用示例： -e="192.168.0.88" 或 -e="192.168.0.88|192.168.0.89" 或 -e

​        -m：部署模式，-m=deploy|install|config|uninstall，默认deploy（安装+配置）

​        -k：开启证书，支持部署单边证书、双边或三边使用，使用示例：-k="host|guest" 或 -k

​                 默认规则：

​                          部署2方，-k无需带参数，默认会把2方角色都自动设置为开启证书。

​                          部署3方，必须指定角色列表。

​                          部署一方，必须使用不带参数。

​        -n: 后端引擎，-n=standalone or eggroll or spark，默认为eggroll，使用示例：-n=spark

​          ***上述参数可以混合使用，多个表示部署多方。***

​

- 使用示例

  - 初始化无需参数值

    ```
    bash deploy/deploy.sh init -h -g -e
    ```

  - 初始化使用实际参数值

    ```
    bash deploy/deploy.sh init -h="10000:192.168.0.1" -g="9999:192.168.1.1"
       -e="192.168.0.88"  -k="host|guest"
    ```



- 使用部署辅助脚本生成ansible配置文件

```
bash deploy/deploy.sh render
```



###### 2.5.2.3 使用部署辅助脚本生成证书

- 使用以下命令生产同一个ca的的证书

  ```
  bash deploy/deploy.sh keys
  ```



- 按需使用以下命令生产不同ca的的证书

  ```
  /bin/bash deploy/deploy.sh keys [host|guest|exchange]  // |表示或，只能选择一个执行脚本

  所有不同ca的证书生成后需要执行cp-keys.sh脚本
  /bin/bash deploy/cp-keys.sh $arg1 $arg2	//arg1、arg2为证书的角色方[host|guest|exchange]
  ```




###### 2.5.2.4 使用部署辅助脚本进行部署或卸载

     /bin/bash deploy/deploy.sh deploy|install|config|uninstall

参数说明：

​                deploy:   安装软件和更新配置

​                install：  安装软件

​                config：  更新配置

​                uninstall： 卸载

单服务或多服务的部署、卸载：

```
1) vim deploy/conf/setup.conf		//按需增加或删减模块，编辑完成后执行render生成配置

deploy_mode: deploy		//deploy、install、config表示部署、uninstall表示卸载
modules:				//调整需要部署或卸载的模块
  - mysql
  - eggroll
  - fate_flow
  - fateboard

2）/bin/bash deploy/deploy.sh render		//生成配置
3）/bin/bash deploy/deploy.sh deploy|uninstall	//执行部署或卸载
```



- 查看部署、卸载日志

```
tailf logs/deploy-??.log				---部署服务的日志，执行部署命令会提示查看
tailf logs/uninstall-??.log				---卸载服务的日志，执行卸载命令会提示查看
```



###### 2.5.2.5 配置文件场景示例

- **spark引擎部署配置文件**

  文件：`deploy/conf/setup.conf`

  ```
  env: prod
  pname: fate
  ssh_port: 22
  deploy_user: app	---部署目标服务的远程连接用户
  deploy_group: apps	---部署目标服务的远程连接用户的用户组
  deploy_mode: deploy

  modules:
    - mysql
    - fate_flow
    - fateboard
  roles:
    - host:10000
    - guest:9999

  host_ips:
    - default:192.168.0.1
  host_special_routes: []
  guest_ips:
    - default:192.168.1.1
  guest_special_routes: []

  default_engines: spark
  #host spark configuration information
  #compute_engine: spark
  host_compute_engine: spark
  host_spark_home: ""
  host_hadoop_home: ""
  #storage_engine: hive or hdfs or localfs
  host_storage_engine: hive
  host_hive_ips: ""
  host_hdfs_addr: ""
  #mq_engine: rabbitmq or pulsar
  host_mq_engine: rabbitmq
  host_rabbitmq_ips: ""
  host_pulsar_ips: ""
  #proxy
  host_nginx_ips: ""

  #
  #guest spark configuration information
  #compute_engine: spark
  guest_compute_engine: spark
  guest_spark_home: ""
  guest_hadoop_home: ""
  #storage_engine: hive or hdfs or localfs
  guest_storage_engine: hive
  guest_hive_ips: ""
  guest_hdfs_addr: ""
  #mq_engine: rabbitmq or pulsar
  guest_mq_engine: rabbitmq
  guest_rabbitmq_ips: ""
  guest_pulsar_ips: ""
  #proxy
  guest_nginx_ips: ""
  ```

- **非spark引擎部署配置文件**

  文件：`deploy/conf/setup.conf`

  ```
  env: prod
  pname: fate
  ssh_port: 22
  deploy_user: app	---部署目标服务的远程连接用户
  deploy_group: apps	---部署目标服务的远程连接用户的用户组
  deploy_mode: deploy

  modules:
    - mysql
    - eggroll
    - fate_flow
    - fateboard
  roles:
    - host:10000
    - guest:9999
  ssl_roles: []
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



- **部署配置文件讲解参数说明：**

  ```
  1，deploy_mode： 部署模式。 取值有： deploy、install、config、uninstall，设置方式： 默认deploy表示安装软件并配置服务，install只安装软件，config只更新配置服务，uninstall表示卸载。

  2，modules：需要的部署的模块。取值有：mysql、eggroll 、fate_flow、fateboard，设置方式： 单独一个，多个或者全部。例：modules: ['mysql','eggroll']

  3，roles：需要部署的某一端的角色。取值有： host、 guest、exchange，设置方式： 3个任意组合。

  4，ssl_roles： 使用证书的角色。取值有： host、 guest、exchange，设置方式： 空值或三选二。 三边部署不支持-k="host|guest"；不支持spark场景

  5，polling： polling的角色。取值有： 字典，包含服务端的角色和客户端的角色，格式： { "server_role": "exchange", "client_role": "host" }，设置方式： 空值或字典。（部署2方或者3方才支持）

  6，host_ips：host端机器列表。取值有： "default:ip"、"rollsite:ip"、"nodemanager:ip"、"clustermanager:ip"、"fate_flow:ip"、"fateboard:ip"，设置方式： 只设default:ip,  或多个，或全部。nodemanager设置的多个ip使用|分割，其他组件不支持设置多个ip。

  7，host_special_routes： host端额外路由。取值有： 数组，成员格式：party_id:ip:port,设置方式：可以设置零个、一个或多个。例：- 8888:192.168.1.2:9370（支持证书方式: - 8888:192.168.1.2:9371:secure），额外路由指向exchange示例为： - default:192.168.1.2:9370

  8，guest_ips：guest端机器列表。取值有： "default:ip"、"rollsite:ip"、"nodemanager:ip"、"clustermanager:ip"、"fate_flow:ip"、"fateboard:ip"，设置方式： 只设default:ip,  或多个，或全部。nodemanager设置的多个ip使用|分割，其他组件不支持设置多个ip。

  9，guest_special_routes： guest端额外路由。取值有： 数组，成员格式：party_id:ip:port, 设置方式： 可以设置零个、一个或多个。（支持证书方式：- 8888:192.168.1.2:9371:secure），指向exchange示例为： - default:192.168.1.2:9370

  10，exchange_ips： exchange端机器列表，取值："default:ip列表"、"rollsite:ip列表" ，设置方式： 二选一。多个exchange_ip使用|分割。

  11，exchange_special_routes：exchange端额外路由。取值有： 数组，成员格式：party_id:ip:port, 设置方式： 可以设置零个、一个或多个。（支持配置使用证书方式： - 8888:192.168.1.2:9371:secure）

  12，默认路由的设置，请参考2.4.8“路由支持”一节的介绍。
  13，default_engines：fate使用的引擎，默认为eggroll，取值列表（eggroll、standalone、spark）

  14，host_compute_engine：计算引擎，取值：（spark）；设置spark可启动spark配置。
  15，host_spark_home：spark目录，默认使用环境变量的SPARK_HOME。
  16，host_hadoop_home: hadoop服务目录
  17，host_storage_engine：存储引擎，取值（hive、hdfs、localfs）三选一。
  18，host_hive_ips：hive的IP地址。
  19，host_hdfs_addr：hdfs的address地址。示例：hdfs://fate-cluster
  20，host_mq_engine：需要部署的mq组件，取值（rabbitmq、pulsar）二选一。
  21，host_rabbitmq_ips：需要部署rabbitmq的IP地址，若rabbitmq和fate分离部署，需要手动添加rabbitmq的IP至environment/prod/hosts文件的fate组下
  22，host_pulsar_ips：需要部署pulsar的IP地址
  23，host_nginx_ips：nginx代理IP，填写开启nginx配置
  ```




- **场景1：单部署host**

  命令： `sh deploy/deploy.sh init -h="10000:192.168.0.1"`

  配置文件：`vim deploy/conf/setup.conf`

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
  ssl_roles: []
  polling: {}
  host_ips:
    - default:192.168.0.1
  host_special_routes: []
  guest_ips: []
  guest_special_routes: []
  exchange_ips: []
  exchange_special_routes: []
  default_engines: eggroll
  ```

​      参数说明：

​		modules：部署模块，按需求填写，例： modules: ['mysql','eggroll']

​		host_special_routes：host端额外路由，一般指向exchange，数组格式：party_id:ip:port，指向exchange				例：host_special_routes: [ 'default:192.168.0.88:9370' ]

​		default_engines: eggroll,默认后端引擎

- **场景2：单部署exchange**

  命令：`sh deploy/deploy.sh  init -e="192.168.0.88" `

  配置文件：`vim deploy/conf/setup.conf`

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
    - exchange:0
  ssl_roles: []
  polling: {}
  host_ips: []
  host_special_routes: []
  guest_ips: []
  guest_special_routes: []
  exchange_ips:
    - default:192.168.0.88
  exchange_special_routes: []
  default_engines: eggroll
  ```

​		参数说明：

​		exchange_special_routes：exchange端额外路由，数组格式：party_id:ip:port，指向其他party例：					exchange_special_routes: [ '8888:192.168.2.1:9370' ]

- **场景3：部署两方exchange-guest**

  命令： `sh deploy/deploy.sh init -g="9999:192.168.1.1" -e="192.168.0.88" -k="guest|exchange" `

  配置文件：`vim deploy/conf/setup.conf`

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
    - guest:9999
    - exchange:0
  ssl_roles:
    - guest
    - exchange
  polling: {}
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

  参数说明：

  ssl_roles：证书启用方

- **场景4：部署两方host-guest（spark）**

  命令： `sh deploy/deploy.sh init -h="10000:192.168.0.1" -g="9999:192.168.1.1" -n=spark`

  配置文件：`vim deploy/conf/setup.conf`

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

  host_ips:
    - default:192.168.0.1
  host_special_routes: []
  guest_ips:
    - default:192.168.1.1
  guest_special_routes: []
  default_engines: spark
  #host spark configuration information
  #compute_engine: spark
  host_compute_engine: spark
  host_spark_home: ""
  host_hadoop_home: ""
  #storage_engine: hive or hdfs or localfs
  host_storage_engine: hive
  host_hive_ips: ""
  host_hdfs_addr: ""
  #mq_engine: rabbitmq or pulsar
  host_mq_engine: rabbitmq
  host_rabbitmq_ips: ""
  host_pulsar_ips: ""
  #proxy
  host_nginx_ips: ""

  #
  #guest spark configuration information
  #compute_engine: spark
  guest_compute_engine: spark
  guest_spark_home: ""
  guest_hadoop_home: ""
  #storage_engine: hive or hdfs or localfs
  guest_storage_engine: hive
  guest_hive_ips: ""
  guest_hdfs_addr: ""
  #mq_engine: rabbitmq or pulsar
  guest_mq_engine: rabbitmq
  guest_rabbitmq_ips: ""
  guest_pulsar_ips: ""
  #proxy
  guest_nginx_ips: ""
  ```

- **场景5：部署两方host-guest（非spark）**

  命令： `sh deploy/deploy.sh init -h="10000:192.168.0.1" -g="9999:192.168.1.1" -k`

  配置文件：`vim deploy/conf/setup.conf`

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

- **场景6：部署三方host-guest-exchange**

  命令： `sh deploy/deploy.sh init -h="10000:192.168.0.1" -g="9999:192.168.1.1" -e="192.168.0.88" -k="host|exchange"`

  配置文件：`vim deploy/conf/setup.conf`

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
    - exchange:0
  ssl_roles:
  - host
    - exchange
  polling: {}
  host_ips:
    - default:192.168.0.1
  host_special_routes: []
  guest_ips:
    - default:192.168.1.1
  guest_special_routes: []
  exchange_ips:
    - default:192.168.0.88
  exchange_special_routes: []
  default_engines: eggroll
  ```




##### 2.5.3 ansible配置文件

###### 2.5.3.1 配置base信息

- 涉及建立基础目录和安装基础依赖包等。（涉及sudo/root权限操作）

```
vi var_files/prod/base_init
```

- 内容如下：

```
base_dir: "/etc/ansible"

//目录可以根据实际情况调整
base: "/data"
pbase: "/data/projects"				---项目根目录
dbase: "/data/projects/data"		---数据目录
cbase: "/data/projects/common"		---工具类部署目录（包含supervisor和miniconda的路径）
sbase: "/data/projects/snmp"
lbase: "/data/logs"					---日志目录
tbase: "/data/temp"					---临时目录
bbase: "/data/projects/backups"		---备份目录

envCheck: True		---设置为False会跳过环境检查

init:
  dirs:
  - "common"
  - "snmp"

supervisord:
  version: 1.1.4
  account:
    name: "root"				---supervisor登陆账号
    password: "fate"		---supervisor登陆密码
  service:
    owner: "app"	---supervisor启动用户，也是服务启动用户，按情况调整
    group: "apps"   ---用户的用户组，按情况调整
    ip: "127.0.0.1"	---supervisor启动IP
    port: 9001		---supervisor启动端口

```



###### 2.5.3.2 配置fate基础信息

涉及各个组件的版本。

```
vi var_files/prod/fate_init
```

内容如下：	无需修改配置

```
deploy_mode: deploy	---部署模式，安装install 、配置config、卸载uninstall，脚本自动替换
deploy_modules:		---部署模块
  - mysql
  - eggroll
  - fate_flow
  - fateboard

deploy_roles:		---部署角色
  - exchange
  - guest
  - host

ssl_roles:			---证书角色
  - host
  - exchange

default_engines: eggroll	---默认后端引擎
pname: "fate"			---项目名称

python:					---python部署信息
  version: 4.5.4        --不同的包会随安全更新版本
  dest: "miniconda3"
  venv: "common/python/venv"

java:					---java部署信息
  name: "jdk"
  version: "8u192"
  path: "common/jdk"

mysql:					---mysql部署信息
  version: "8.0.28"     --不同的包会随安全更新版本
  path: "common/mysql"
  user: "root"			---mysql数据库管理账号，使用外部mysql需要修改此参数为实际使用账号
  passwd: "fatE168dev"	---mysql数据库管理密码，使用外部mysql需要修改此参数为实际使用密码
```

**这个配置文件以及文档其余部分涉及的组件版本，以下载的部署包提供的版本为准。文档中的版本号仅用于展示配置的设置**

###### 2.5.3.3 配置Exchange信息

按需修改，不部署则跳过此步骤

```
vi var_files/prod/fate_exchange
```

内容如下：

```
exchange:
  rollsite:
    enable: True
    coordinator: fate
    ips:			---rollsite IP列表
    - 192.168.0.88
    port: 9370		---rollsite服务端口
    secure_port: 9371		---开启证书通讯时对外的端口
    server_secure: False	---作为服务端，使用证书验证，开启True
    client_secure: False	---作为客户端，使用证书验证，开启True
  	polling:
      enable: False	//polling设置开关，开启设置为True
      ids:			//开启polling，可以支持多方polling
      - 10000		//与exchange通讯的polling对端
      - 9999
    route_tables: 			---exchange路由表，指向各party的路由配置
    - id: 10000			---路由表party_id
      routes:
      - name: default
        ip: 192.168.0.1		---party_id为10000集群下的rollsite IP
        port: 9370			---开启证书设置为9371
        is_secure: False	---开启证书设置为true，并把上面的port端口设置为9371
    - id: 9999
      routes:
      - name: default
        ip: 192.168.1.1		---party_id为9999集群下的rollsite IP
        port: 9370			---开启证书设置为9371
        is_secure: False	---开启证书设置为true，并把上面的port端口设置为9371
```



###### 2.5.3.4  配置Host信息

按需修改，不部署则跳过此步骤

```
vi var_files/prod/fate_host
```

- spark引擎场景配置请参考如下：

```
host:
  partyid: 10000   ---host端partyid，根据实际规划修改
  fate_flow:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.0.1		---只支持部署一台主机
    grpcPort: 9360	---grpc服务端口
    httpPort: 9380	---http服务端口
    dbname: "fate_flow"	---数据库名称
    proxy: rollsite			---可选值：rollsite|fateflow|nginx，fateflow和nginx用于spark
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll	---可选值：standalone、eggroll、spark等
    federation: rabbitmq		---可选：rabbitmq或pulsar
    storage: hdfs				---存储引擎：hdfs，hive和localfs
  fateboard:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.0.1		---只支持部署一台主机
    port: 8080		---服务端口
    dbname: "fate_flow"	---数据库名称
  mysql:
    enable: True		---true为需要部署此模块，False则否
    type: inside		---inside表示内部数据库，自动部署；outside表示外部数据库，不提供部署
    ips:
    - 192.168.0.1		---只支持部署一台主机
    port: 3306		---服务端口
    dbuser: "fate"	---数据库业务账号，使用外部mysql可修改此参数
    dbpasswd: "fate_deV2999"	---数据库业务密码，使用外部mysql可修改此参数
  zk:					---不支持部署zk，配置信息用于fateflow
    enable: False		---true为开启zk配置信息，False则否
    lists:			---zk集群IP列表
    - ip: 192.168.0.1
      port: 2181		---zk服务端口
    use_acl: false	---zk是否启动acl
    user: "fate"		---acl用户
    passwd: "fate"	---acl密码
  servings:			---serving-server配置信息
    ips:				---serving集群IP列表，配置host端serving
    - 192.168.0.1
    port: 8000		---服务端口
  spark:			---开启spark信息
    enable: False
    home:
    hadoop_home:
    cores_per_node: 20
    nodes: 2
  hive:
    enable: False
    host: 127.0.0.1
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
    enable: False
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
    enable: False
    host: 127.0.0.1
    http_port: 9300
    grpc_port: 9310
```

- 非spark引擎场景配置请参考如下：

```
host:
  partyid: 10000   ---host端partyid，根据实际规划修改
  rollsite:
    enable: True   ---true为需要部署此模块，False则否
    coordinator: fate
    ips:			---IP列表，目前rollsite只支持部署到一台服务器
    - 192.168.0.1
    port: 9370	---服务端口
    secure_port: 9371		---开启证书通讯时对外的端口
    server_secure: False	---作为服务端，使用证书验证，开启True
    client_secure: False	---作为客户端，使用证书验证，开启True
    polling:
      enable: False		---polling设置开关，开启设置为True
    route_tables:	---host端路由表
    - id: default		------本party指向exchange或者其他party的IP，端口路由配置
      routes:
      - name: default	---默认路由表，目前支持一个默认路由。如果有exchange，则指向exchange，如无，则指向对端party。
        ip: 192.168.0.88	---exchange或者对端party rollsite IP
        port: 9370		---exchange或者对端party rollsite 端口，默认9370
        is_secure: False	---host开启证书设置为true
    - id: 10000		---本party自身路由配置
      routes:
      - name: default
        ip: 192.168.0.1	---rollsitede IP
        port: 9370
        is_secure: false
      - name: fateflow
        ip: 192.168.0.1	---fateflow IP
        port: 9360
  clustermanager:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.0.1		---只支持部署一台主机
    port: 4670		---服务端口
    cores_per_node: 16	---设置cpu核数，统一为nodemanager所在机器的总cpu核数
  nodemanager:		---可以多节点，在ips中加配置
    enable: True		---true为需要部署此模块，False则否
    ips:		---支持部署多台
    - 192.168.0.1
    - 192.168.0.x
    port: 4671	---服务端口
  eggroll:
    dbname: "eggroll_meta"	---eggroll使用的数据库名，默认即可
    egg: 4					---egg并发数可以根据附录公式计算修改
  fate_flow:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.0.1		---只支持部署一台主机
    grpcPort: 9360	---grpc服务端口
    httpPort: 9380	---http服务端口
    dbname: "fate_flow"	---数据库名称
    proxy: rollsite			---可选值：rollsite|fateflow|nginx，fateflow和nginx用于spark
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll	---可选值：standalone、eggroll、spark等
  fateboard:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.0.1		---只支持部署一台主机
    port: 8080		---服务端口
    dbname: "fate_flow"	---数据库名称
  mysql:
    enable: True		---true为需要部署此模块，False则否
    type: inside		---inside表示内部数据库，自动部署；outside表示外部数据库，不提供部署
    ips:
    - 192.168.0.1		---只支持部署一台主机
    port: 3306		---服务端口
    dbuser: "fate"	---数据库业务账号，使用外部mysql可修改此参数
    dbpasswd: "fate_deV2999"	---数据库业务密码，使用外部mysql可修改此参数
  zk:					---不支持部署zk，配置信息用于fateflow
    enable: False		---true为开启zk配置信息，False则否
    lists:			---zk集群IP列表
    - ip: 192.168.0.1
      port: 2181		---zk服务端口
    use_acl: false	---zk是否启动acl
    user: "fate"		---acl用户
    passwd: "fate"	---acl密码
  servings:			---serving-server配置信息
    ips:				---serving集群IP列表，配置host端serving
    - 192.168.0.1
    port: 8000		---服务端口
```



###### 2.5.3.5 配置Guest信息

按需修改，不部署则跳过此步骤

```
vi var_files/prod/fate_guest
```

- spark引擎场景配置请参考如下：

```
guest:
  partyid: 9999   ---guest端partyid，根据实际规划修改
  fate_flow:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.1.1		---只支持部署一台主机
    grpcPort: 9360	---grpc服务端口
    httpPort: 9380	---http服务端口
    dbname: "fate_flow"	---数据库名称
    proxy: rollsite			---可选值：rollsite|fateflow|nginx，fateflow和nginx用于spark
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll	---可选值：standalone、eggroll、spark等
    federation: rabbitmq		---可选：rabbitmq或pulsar
    storage: hdfs				---存储引擎：hdfs，hive和localfs
  fateboard:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.1.1		---只支持部署一台主机
    port: 8080		---服务端口
    dbname: "fate_flow"	---数据库名称
  mysql:
    enable: True		---true为需要部署此模块，False则否
    type: inside		---inside表示内部数据库，自动部署；outside表示外部数据库，不提供部署
    ips:
    - 192.168.1.1		---只支持部署一台主机
    port: 3306		---服务端口
    dbuser: "fate"	---数据库业务账号，使用外部mysql可修改此参数
    dbpasswd: "fate_deV2999"	---数据库业务密码，使用外部mysql可修改此参数
  zk:					---不支持部署zk，配置信息用于fateflow
    enable: False		---true为开启zk配置信息，False则否
    lists:			---zk集群IP列表
    - ip: 192.168.1.1
      port: 2181		---zk服务端口
    use_acl: false	---zk是否启动acl
    user: "fate"		---acl用户
    passwd: "fate"	---acl密码
  servings:			---serving-server配置信息
    ips:				---serving集群IP列表，配置guest端serving
    - 192.168.1.1
    port: 8000		---服务端口
  spark:			---开启spark信息
    enable: False
    home:
    hadoop_home:
    cores_per_node: 20
    nodes: 2
  hive:
    enable: False
    host: 127.0.0.1
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
    enable: False
    host: 192.168.1.1
    mng_port: 12345
    port: 5672
    user: fate
    password: fate
    route_table:
      - id: 10000
        routes:
          - ip: 192.168.1.1
            port: 5672
  pulsar:
    enable: False
    host: 192.168.1.1
    port: 6650
    mng_port: 8080
    topic_ttl: 5
    route_table:
      - id: 10000
        routes:
          - ip: 192.168.1.1
            port: 6650
            sslPort: 6651
            proxy: ""
  nginx:
    enable: False
    host: 127.0.0.1
    http_port: 9300
    grpc_port: 9310
```

- 非spark引擎场景配置请参考如下：

```
guest:
  partyid: 9999   ---guest端partyid，根据实际规划修改
  rollsite:
    enable: True   ---true为需要部署此模块，False则否
    coordinator: fate
    ips:			---IP列表，目前rollsite只支持部署到一台服务器
    - 192.168.1.1
    port: 9370	---服务端口
    secure_port: 9371		---开启证书通讯时对外的端口
    server_secure: False	---作为服务端，使用证书验证，开启True
    client_secure: False	---作为客户端，使用证书验证，开启True
    polling:
      enable: False		---polling设置开关，开启设置为True
    route_tables:	---host端路由表
    - id: default		------本party指向exchange或者其他party的IP，端口路由配置
      route:
      - name: default	---默认路由表，目前支持一个默认路由。如果有exchange，则指向exchange，如无，则指向对端party。
        ip: 192.168.0.88	---exchange或者对端party rollsite IP
        port: 9370		---exchange或者对端party rollsite 端口，默认9370
        is_secure: False	---guest开启证书设置为true
    - id: 10000		---本party自身路由配置
      route:
      - name: default
        ip: 192.168.1.1	---rollsitede IP
        port: 9370
        is_secure: false
      - name: fateflow
        ip: 192.168.1.1	---fateflow IP
        port: 9360
  clustermanager:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.1.1		---只支持部署一台主机
    port: 4670		---服务端口
    cores_per_node: 16	---设置cpu核数，统一为nodemanager所在机器的总cpu核数
  nodemanager:		---可以多节点，在ips中加配置
    enable: True		---true为需要部署此模块，False则否
    ips:		---支持部署多台
    - 192.168.1.1
    - 192.168.1.x
    port: 4671	---服务端口
  eggroll:
    dbname: "eggroll_meta"	---eggroll使用的数据库名，默认即可
    egg: 4					---egg并发数可以根据附录公式计算修改
  fate_flow:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.1.1		---只支持部署一台主机
    grpcPort: 9360	---grpc服务端口
    httpPort: 9380	---http服务端口
    dbname: "fate_flow"	---数据库名称
    proxy: rollsite			---可选值：rollsite|fateflow|nginx，fateflow和nginx用于spark
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll	---可选值：standalone、eggroll、spark等
  fateboard:
    enable: True		---true为需要部署此模块，False则否
    ips:
    - 192.168.1.1		---只支持部署一台主机
    port: 8080		---服务端口
    dbname: "fate_flow"	---数据库名称
  mysql:
    enable: True		---true为需要部署此模块，False则否
    type: inside		---inside表示内部数据库，自动部署；outside表示外部数据库，不提供部署
    ips:
    - 192.168.1.1		---只支持部署一台主机
    port: 3306		---服务端口
    dbuser: "fate"	---数据库业务账号，使用外部mysql可修改此参数
    dbpasswd: "fate_deV2999"	---数据库业务密码，使用外部mysql可修改此参数
  zk:					---不支持部署zk，配置信息用于fateflow
    enable: False		---true为开启zk配置信息，False则否
    lists:			---zk集群IP列表
    - ip: 192.168.1.1
      port: 2181		---zk服务端口
    use_acl: false	---zk是否启动acl
    user: "fate"		---acl用户
    passwd: "fate"	---acl密码
  servings:			---serving-server配置信息
    ips:				---serving集群IP列表，配置guest端serving
    - 192.168.1.1
    port: 8000		---服务端口
```



###### 2.5.3.6 配置任务列表

修改文件：(默认不需要修改)

```
vi project_prod.yaml
```

spark引擎场景配置project_prod.yaml内容如下：

```
- hosts: fate
  any_errors_fatal: True
  vars:
    jbase: "{{pbase}}/{{pname}}/{{java['path']}}/{{java['name']}}-{{java['version']}}"
    pybase: "{{pbase}}/{{pname}}/{{python['venv']}}"
    pypath: "{{pbase}}/{{pname}}/python:{{pbase}}/{{pname}}/eggroll/python"
  vars_files:
  - var_files/prod/base_init
  - var_files/prod/fate_init
  - var_files/prod/fate_host
  - var_files/prod/fate_guest
  roles:
  - base
  - supervisor
  - { role: "mysql", when: "( 'host' in deploy_roles and ansible_ssh_host in host['mysql']['ips'] and host['mysql']['enable'] == True and host['mysql']['type'] == 'inside' and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['mysql']['ips'] and guest['mysql']['enable'] == True and guest['mysql']['type'] == 'inside' and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "python", when: "( 'host' in deploy_roles and ansible_ssh_host in host['fate_flow']['ips'] and host['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ]  ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fate_flow']['ips'] and guest['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "rabbitmq", when: "( 'host' in deploy_roles and ansible_ssh_host == host['rabbitmq']['host'] and host['rabbitmq']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host == guest['rabbitmq']['host'] and guest['rabbitmq']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "fateflow", when: "( 'host' in deploy_roles and ansible_ssh_host in host['fate_flow']['ips'] and host['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fate_flow']['ips'] and guest['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "fateboard", when: "( 'host' in deploy_roles and ansible_ssh_host in host['fateboard']['ips'] and host['fateboard']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fateboard']['ips'] and guest['fateboard']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
```

非spark引擎场景配置project_prod.yaml内容如下：

```
- hosts: fate
  any_errors_fatal: True
  vars:
    jbase: "{{pbase}}/{{pname}}/{{java['path']}}/{{java['name']}}-{{java['version']}}"
    pybase: "{{pbase}}/{{pname}}/{{python['venv']}}"
    pypath: "{{pbase}}/{{pname}}/python:{{pbase}}/{{pname}}/eggroll/python"
  vars_files:
  - var_files/prod/base_init
  - var_files/prod/fate_init
  - var_files/prod/fate_host
  - var_files/prod/fate_guest
  - var_files/prod/fate_exchange
  roles:
  - base
  - supervisor
  - { role: "mysql", when: "( 'host' in deploy_roles and ansible_ssh_host in host['mysql']['ips'] and host['mysql']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['mysql']['ips'] and guest['mysql']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "python", when: "( 'host' in deploy_roles and ansible_ssh_host in host['fate_flow']['ips'] and host['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ]  ) or ( 'host' in deploy_roles and ansible_ssh_host in host['nodemanager']['ips'] and host['nodemanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fate_flow']['ips'] and guest['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['nodemanager']['ips'] and guest['nodemanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "eggroll", when: "( ( 'exchange' in deploy_roles and ansible_ssh_host in exchange['rollsite']['ips'] and exchange['rollsite']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or  ( 'host' in deploy_roles and ansible_ssh_host in host['rollsite']['ips'] and host['rollsite']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'host' in deploy_roles and ansible_ssh_host in host['clustermanager']['ips'] and host['clustermanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'host' in deploy_roles and ansible_ssh_host in host['nodemanager']['ips'] and host['nodemanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )  or ( 'host' in deploy_roles and ansible_ssh_host in host['fate_flow']['ips'] and host['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['rollsite']['ips'] and guest['rollsite']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['clustermanager']['ips'] and guest['clustermanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['nodemanager']['ips'] and guest['nodemanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fate_flow']['ips'] and guest['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) )" }
  - { role: "fateflow", when: "( 'host' in deploy_roles and ansible_ssh_host in host['fate_flow']['ips'] and host['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'host' in deploy_roles and ansible_ssh_host in host['nodemanager']['ips'] and host['nodemanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fate_flow']['ips'] and guest['fate_flow']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['nodemanager']['ips'] and guest['nodemanager']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
  - { role: "fateboard", when: "( 'host' in deploy_roles and ansible_ssh_host in host['fateboard']['ips'] and host['fateboard']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] ) or ( 'guest' in deploy_roles and ansible_ssh_host in guest['fateboard']['ips'] and guest['fateboard']['enable'] == True and deploy_mode in [ 'deploy', 'install', 'config' ] )" }
```



###### 2.5.3.7 配置主机列表

修改文件：(默认不需要修改)

```
vi environments/prod/hosts
```

内如如下：

```
[all:vars]
ansible_connection=ssh
ansible_ssh_port=36000		---远程连接端口
ansible_ssh_user=app		---远程执行用户，同时也是部署用户
#ansible_ssh_pass=
##method: sudo or su
ansible_become_method=sudo
ansible_become_user=root
ansible_become_pass=
[deploy_check]
---fate组为同时部署host、guest和exchange的IP列表
[fate]
192.168.0.88
192.168.1.1
192.168.0.1
```

**若需在ansible本机安装且不经过ssh，则在IP后面添加 ansible_connection=local，如下**

```
[fate]
192.168.0.88 ansible_connection=local
```

**若部署spark场景，rabbitmq和fate分离部署，需要手动添加rabbitmq的IP至fate组下**

#### 2.6 部署流程

##### 2.6.1 下载

###### 2.6.1.1 下载离线包

- 离线包解压后初始化配置后可直接部署

```
wget https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/AnsibleFATE_${version}_release-offline.tar.gz
tar xzf AnsibleFATE_${version}_release-offline.tar.gz
cd AnsibleFATE-${version}-release-offline

//version>=1.7.0，按需设置
```


###### 2.6.1.2下载在线包

```
wget https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/AnsibleFATE_${version}_release-online.tar.gz
tar xzf AnsibleFATE_${version}_release-online.tar.gz
cd AnsibleFATE-${version}-release-online

//version>=1.7.0
```


##### 2.6.2 使用初始化脚本生成部署配置文件

部署配置文件： deploy/conf/setup.conf

```
Usage:  /bin/bash deploy/deploy.sh init -h|-g|-e|-m|-k
     args:
         -h=ip
         -g=ip
         -e=ip or ips
         -m=install or uninstall
         -k=both roles of keys(eg: host|guest)
         -n=standalone or eggroll or spark（default： eggroll）
```



##### 2.6.3 调整参数并生成ansible配置文件

- 手工修改配置文件

```
vi deploy/conf/setup.conf
```

- 生成ansible配置文件: var_files/prod/***

```
 /bin/bash deploy/deploy.sh render
```



##### 2.6.4 执行ping测试(可选)

```
 /bin/bash deploy/deploy.sh ping
```



##### 2.6.5 生成证书(可选)

```
 /bin/bash deploy/deploy.sh keys							---生成同一ca证书

 /bin/bash deploy/deploy.sh keys [host|guest|exchange]		---生成不同ca证书，选择一方执行
 不同ca的证书生成后需要执行cp-keys.sh脚本
 /bin/bash deploy/cp-keys.sh $arg1 $arg2	//arg1、arg2为证书的角色方[host|guest|exchange]
```



##### 2.6.6 执行部署（按需）

```
 /bin/bash deploy/deploy.sh deploy|install|config|uninstall
```



##### 2.6.7 检查服务

详看2.7.1一节。

##### 2.6.8 执行部署后置操作

后置操作请参考： <<[部署fate集群的后置操作](action_after_deploy_fate_cluster.md)>> 一文。

##### 2.6.9 执行测试

跑toy测试和最小化测试（详看2.7.2节”Toy_example部署验证“和2.7.3节“最小化测试”）


#### 2.7 服务验证

##### 2.7.1 服务进程验证

**访问fateboard**

浏览器访问http://192.168.0.1:8080 or http://192.168.1.1:8080

**查看进程和端口**

使用ps、losf、ss等命令查看已经部署的服务的进程和端口。

- 查看进程

```
ps aux|grep fate

/bin/bash  /data/projects/common/supervisord/service.sh  status all
```

- 查看在监听的所有tcp端口

```
ss -lnt
```

- 查看指定端口是否监听

```
lsof -i :9370
```



##### 2.7.2 Toy_example部署验证
-----------------------

此测试您需要设置2个参数：gid(guest partyid)，hid(host_partyid)。

###### 2.7.2.1 单边测试

1）192.168.0.1上执行，gid和hid都设为10000：

```
source /data/projects/fate/bin/init_env.sh
flow test toy -gid 10000 -hid 10000
```

类似如下结果表示成功：

"2020-04-28 18:26:20,789 - secure_add_guest.py[line:126] - INFO: success to calculate secure_sum, it is 1999.9999999999998"

提示：如出现max cores per job is 1, please modify job parameters报错提示，需要修改运行时参数task_cores为1，增加命令行参数 '--task-core 1'.

2）192.168.0.2上执行，gid和hid都设为9999：

```
source /data/projects/fate/bin/init_env.sh
flow test toy -gid 9999 -hid 9999
```

类似如下结果表示成功：

"2020-04-28 18:26:20,789 - secure_add_guest.py[line:126] - INFO: success to calculate secure_sum, it is 1999.9999999999998"

###### 2.7.2.2 双边测试

选定9999为guest方，在192.168.0.2上执行：

```
source /data/projects/fate/bin/init_env.sh
flow test toy -gid 9999 -hid 10000
```

类似如下结果表示成功：

"2020-04-28 18:26:20,789 - secure_add_guest.py[line:126] - INFO: success to calculate secure_sum, it is 1999.9999999999998"



##### 2.7.3 最小化测试
--------------

###### **2.7.3.1 上传预设数据**

分别在192.168.0.1和192.168.0.2上执行：

```
source /data/projects/fate/bin/init_env.sh
cd /data/projects/fate/examples/scripts/
python upload_default_data.py
```

更多细节信息，敬请参考[脚本README](../../../../examples/scripts/README.rst)

###### **2.7.3.2 快速模式**

请确保guest和host两方均已分别通过给定脚本上传了预设数据。

快速模式下，最小化测试脚本将使用一个相对较小的数据集，即包含了569条数据的breast数据集。

选定9999为guest方，在192.168.0.2上执行：

```
source /data/projects/fate/bin/init_env.sh
cd /data/projects/fate/examples/min_test_task/
#单边测试
python run_task.py -gid 9999 -hid 9999 -aid 9999 -f fast
#双边测试
python run_task.py -gid 9999 -hid 10000 -aid 10000 -f fast
```

其他一些可能有用的参数包括：

1. -f: 使用的文件类型. "fast" 代表 breast数据集, "normal" 代表 default credit 数据集.
2. --add_sbt: 如果被设置为1, 将在运行完lr以后，启动secureboost任务，设置为0则不启动secureboost任务，不设置此参数系统默认为1。

若数分钟后在结果中显示了“success”字样则表明该操作已经运行成功了。若出现“FAILED”或者程序卡住，则意味着测试失败。

###### **2.7.3.3 正常模式**

只需在命令中将“fast”替换为“normal”，其余部分与快速模式相同。



#### 2.8 服务运维

**服务管理**

进入supervisor目录

```
cd /data/projects/common/supervisord
```

启动/关闭/查看所有：

```
bash service.sh start/stop/status all
```

启动/关闭/查看单个模块(可选：clustermanager，nodemanager，rollsite，fateflow，fateboard，mysql)：

```
bash service.sh start/stop/status fate-clustermanager
```

**服务日志**

| 服务      | 进程关键字                            | 日志路径                   |
| --------- | ------------------------------------- | -------------------------- |
| eggroll   | ClusterManager、NodeManager、rollsite | /data/logs/fate/eggroll/   |
| fate_flow | fate_flow_server                      | /data/logs/fate/fateflow/  |
| mysql     | mysql                                 | /data/logs/mysql/          |
| fateboard | fateboard                             | /data/logs/fate/fateboard/ |



### 3 特定操作指引

#### 3.1 使用自签证书

自签证书的名称需要和部署脚本的统一，包含ca.pem、server.pem、server.key、client.pem、client.key文件，每个部署角色的证书文件都需要包含这五个文件。

- **在已有证书的fate环境下替换自签证书的场景（假设证书为guest+exchange）**

1）当自签证书的名称不一样，需要如下操作，每个角色的证书都需要操作：

​	1、ca.pem：ca根证书，类似ca.crt文件，名称不一致使用cp命令重命名文件；例如：`cp ca.crt ca.pem`

​	2、server.pem：server服务端证书，类似server.crt文件，名称不一致使用cp命令重命名文件；例如：`cp server.crt server.pem`

​	3、server.key：server服务端私钥，制作私钥时可以指定名称，若名称不一致使用cp命令重命名文件

​	4、client.pem：client客户端证书，类似client.crt文件，名称不一致使用cp命令重命名文件；例如：`cp client.crt client.pem`

​	5、client.key：client客户端私钥，制作私钥时可以指定名称，若名称不一致使用cp命令重命名文件

2）将角色的证书拷贝到对应角色主机的证书路径下（假设证书文件在角色名对应的文件夹中，远程用户app）

```
scp guest/* app@guestip:/data/projects/data/fate/keys/
scp exchange/* app@exchangeip:/data/projects/data/fate/keys/

//guestip和exchangeip根据实际IP填写
```

3）重启guest和exchange的rollsite服务

```
bash /data/projects/common/supervisord/service.sh restart fate-rollsite
```



#### 3.2 单边部署使用证书场景

部署单边的情况，也支持配置证书。  用脚本只产生一方的证书。然后服务端和客户端的设置使用这个证书。  部署完成之后，用户手工按需替换其他证书

- **部署单边完成后需要替换证书的操作**

1）部署单边host（假设证书方为exchange-host）

```
1、sh deploy/deploy.sh init -h -k
//修改conf/setup.conf的hostip，并设置额外路由为exchange，路由格式为（default:ip:证书端口:secure）
2、sh deploy/deploy.sh keys			//证书制作拷贝
3、将deploy/keys/host/目录下的ca.pem、client.pem、client.key文件远程拷贝到exchange服务器的/data/projects/data/fate/keys/目录下，拷贝对应的名称分别为exchange-client-ca.pem、exchange-client-client.pem、exchange-client-client.key
4、sh deploy/deploy.sh render		//生成ansible配置
5、sh deploy/servicec.sh deploy		//执行部署
```



2）部署单边exchange（假设证书方为exchange-host）

```
1、sh deploy/deploy.sh init -e -k
//修改conf/setup.conf的exchangeip，并设置额外路由为host，路由格式为（host_party:ip:证书端口:secure）
2、sh deploy/deploy.sh keys			//证书制作拷贝
3、将deploy/keys/exchange/目录下的ca.pem、client.pem、client.key文件远程拷贝到host服务器的/data/projects/data/fate/keys/目录下，拷贝对应的名称分别为host-client-ca.pem、host-client-client.pem、host-client-client.key
4、sh deploy/deploy.sh render		//生成ansible配置
5、sh deploy/servicec.sh deploy		//执行部署
```



#### 3.3 mysql使用外部数据库

1）使用root登录数据库授权内网root所有人访问（没有root用户，使用有管理权限的账号登陆）

登陆mysql（需要cd到mysql的目录下）

```
./bin/mysql -uroot -p
```

执行如下sql

```
alter user 'root'@'localhost' identified with mysql_native_password by 'root管理密码';
CREATE USER if not exists root@'%' IDENTIFIED BY "root管理密码";
GRANT ALL ON *.* TO root@'%' WITH GRANT OPTION;
alter user 'root'@'%' identified with mysql_native_password by 'root管理密码';
flush privileges;
```

2）修改var_files/prod/fate_host、fate_guest

```
mysql:
    enable: True
    type: outside			--修改为outside，表示外部
    ips:
      - 192.168.0.1			--填写外部mysql的实际IP
    port: 3306				--填写外部mysql的实际端口
    dbuser: fate
    dbpasswd: fate_deV2999
```

3）修改var_files/prod/fate_init

```
mysql:
  version: "8.0.28"
  path: "common/mysql"
  user: "root"			---mysql数据库管理账号，修改为实际使用的管理账号
  passwd: "fatE168dev"	---mysql数据库管理密码，修改为实际使用的管理密码
```
