

# ansible 部署FATE集群单边场景示例



### 1 概述

​         本文介绍通过ansible 部署FATE集群的单边场景，分别是第二章介绍的单边部署exchange和第三章介绍的部署host以及第四章介绍的部署guest。

#### 1.1  下载部署包

~~~
wget https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/fate/${version}/release/AnsibleFATE_${version}_release_offline.tar.gz
tar xzf AnsibleFATE_${version}_release_offline.tar.gz
cd AnsibleFATE_${version}_release_offline
~~~



### 2 部署exchange

#### 2.1 概述

​        本章是通过ansible 部署FATE集群单边场景之一：单独部署exchange。

​		 在进行部署之前请确认已经执行前置操作.（ 具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.2 章节）



#### 2.2 部署目标介绍

| 角色 | IP           | 端口 | 介绍                        |
| ---- | ------------ | ---- | --------------------------- |
| osx  | 192.168.0.88 | 9370 | 跨站点或者说跨party通讯组件 |



#### 2.3 配置

##### 2.3.1 初始化配置

- 步骤1：下载部署包，请参考本文 **1.1**

- 步骤2：使用辅助脚本产生初始化配置

```
bash deploy/deploy.sh init -e="192.168.0.88"
```

- 步骤3： 按需修改配置

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
  - exchange:0
ssl_roles: []
polling: {}
host_ips: []
host_special_routes: []
guest_ips: []
guest_special_routes: []
exchange_ips:
  - default:192.168.0.88
exchange_special_routes:
  - 10000:192.168.0.1:9370		
  - 9999:192.168.1.1:9370
default_engines: eggroll
```

- 步骤4：执行辅助脚本产生配置

```
bash deploy/deploy.sh render
```

##### 2.3.2 配置exchange信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。

#### 2.4 执行部署

- 执行部署命令

```
bash deploy/deploy.sh deploy
```

查看部署日志：`tailf logs/deploy-??.log`




#### 2.5 服务验证与测试

~~~
sh /data/projects/common/supervisord/service.sh status all

# 服务停止，启动，重启
sh /data/projects/common/supervisord/service.sh stop/start/restart fate-osx
~~~





### 3 部署host

#### 3.1 概述

​      本章是通过ansible 部署FATE集群单边场景之一，单独部署host。在进行部署之前请确认已经执行前置操作,前置操作请参考： <<[部署fate集群的前置操作](action_before_deploy_fate_cluster.md)>> 一文。



#### 3.2 部署目标介绍

| 角色           | IP          | 端口      | 介绍                                   |
| -------------- | ----------- | --------- | -------------------------------------- |
| osx            | 192.168.0.1 | 9370      | 跨站点或者说跨party通讯组件            |
| fate_flow      | 192.168.0.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| dashboard | 192.168.0.1 | 8083 | 联合学习集群管理可视化模块 |
| clustermanager | 192.168.0.1 | 4670      | cluster manager管理集群                |
| nodemanager     | 192.168.0.1 | 4671      | node manager管理每台机器资源           |
| fateboard      | 192.168.0.1 | 8080      | 联合学习过程可视化模块                 |
| mysql          | 192.168.0.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |





#### 3.3 配置

##### 3.3.1 初始化配置

- 步骤1：下载部署包，请参考本文 **1.1**

- 步骤2：使用辅助脚本产生初始化配置

```
bash deploy/deploy.sh init -h="10000:192.168.0.1"
```

- 步骤3： 按需修改配置

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
ssl_roles: []
polling: {}
host_ips:
  - default:192.168.0.1
host_special_routes:
  - default:192.168.0.88:9370		//可以设置额外路由指向exchange
guest_ips: []
guest_special_routes: []
exchange_ips: []
exchange_special_routes: []
default_engines: eggroll
```

- 步骤4：执行辅助脚本产生配置

```
bash deploy/deploy.sh render
```

##### 3.3.2 配置host信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改



#### 3.4 执行部署

- 部署所有服务

```
bash deploy/deploy.sh deploy
```

查看部署日志：`tailf logs/deploy-??.log`



#### 3.5 服务验证与测试

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.7一节。



### 4 部署guest

#### 4.1 概述

​      本章是通过ansible 部署FATE集群单边场景之一，单独部署guest-spark。（部署host类似）



#### 4.2 部署目标介绍

| 角色           | IP          | 端口      | 介绍                                   |
| -------------- | ----------- | --------- | -------------------------------------- |
| osx    | 192.168.0.1 | 9370      | 跨站点或者说跨party通讯组件            |
| fate_flow      | 192.168.0.1 | 9360;9380 | 联合学习任务流水线管理模块             |
| dashboard | 192.168.0.1 | 8083 | 联合学习集群管理可视化模块 |
| clustermanager | 192.168.0.1 | 4670      | cluster manager管理集群                |
| nodemanager     | 192.168.0.1 | 4671      | node manager管理每台机器资源           |
| fateboard      | 192.168.0.1 | 8080      | 联合学习过程可视化模块                 |
| mysql          | 192.168.0.1 | 3306      | 数据存储，clustermanager和fateflow依赖 |



#### 4.3 配置

##### 4.3.1 初始化配置
- 步骤1：下载部署包，请参考本文 **1.1**

- 步骤2：使用辅助脚本产生初始化配置

```
bash deploy/deploy.sh init -g="9999:192.168.0.1" 
```

- 步骤3： 按需修改配置

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
  - guest:9999
host_ips: []
host_special_routes: []
guest_ips:
  - default:192.168.0.1
guest_special_routes:
  - default:192.168.0.88:9370		//可以设置额外路由指向exchange
default_engines: eggroll
```

- 步骤4：执行辅助脚本产生配置

```
bash deploy/deploy.sh render
```

##### 4.3.2 配置guest信息

如需要自定义高级配置，可参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.5.3一节，修改如下文件，默认可以不修改。



#### 4.4 执行部署

- 部署所有服务

```
bash deploy/deploy.sh deploy
```

查看部署日志：`tailf logs/deploy-??.log`



#### 4.5 服务验证与测试

具体操作指引请参考<<[部署手册](ansible_deploy_FATE_manual.md)>> 2.7一节。

