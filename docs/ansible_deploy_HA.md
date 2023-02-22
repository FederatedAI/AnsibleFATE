

#### FATE 高可用部署文档

#### 1. 概述

从 FATE 1.9 开始，Flow 支持每一方同时运行多个 Flow 服务以实现负载均衡和故障转移

#### 2. 依赖

Apache ZooKeeper
Nginx 或其他支持 HTTP 和 GRPC 负载均衡的 web server

##### 2.1 zookeeper

###### 2.1.1 部署

~~~
#部署软件
#在目标服务器（192.168.0.1）app用户下执行:
wget https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/apache-zookeeper-3.5.8-bin.tar.gz
tar -xzf apache-zookeeper-3.5.8-bin.tar.gz 
mv apache-zookeeper-3.5.8-bin zookeeper
ls -lrt
mkdir -p /data/projects/zookeeper/data/zookeeper
mkdir -p /data/projects/zookeeper/logs
~~~

###### 2.1.2 配置

配置文件：/data/projects/zookeeper/conf/zoo.cfg

~~~
#在目标服务器（192.168.0.1）app用户下修改执行
cat > /data/projects/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/projects/zookeeper/data/zookeeper
dataLogDir=/data/projects/zookeeper/logs
clientPort=2181
maxClientCnxns=1000
admin.serverPort=8081
server.1= 192.168.0.1:2888:3888
EOF

#在目标服务器（192.168.0.1）app用户下修改执行
echo 1 > /data/projects/zookeeper/data/zookeeper/myid
~~~

###### 2.1.3  启动

~~~
cd /data/projects/zookeeper/bin/
./zkServer.sh start
./zkServer.sh status
~~~

##### 2.2 Nginx

同一方下只需一个 nginx 实例, 可参考部署文档：[Nginx部署](https://github.com/FederatedAI/FATE/blob/master/deploy/cluster-deploy/doc/fate_on_spark/common/nginx_deployment_guide.zh.md)

请自行部署 nginx 并配置负载均衡，以下是一份基本示例，不建议直接在生存环境使用

~~~
upstream grpc_backend {
    server <flow_server_ip1>:<flow_grpc_port> weight=5 max_fails=2 fail_timeout=60s;
    server <flow_server_ip2>:<flow_grpc_port> weight=5 max_fails=2 fail_timeout=60s;
}

upstream http_backend {
    server <flow_server_ip1>:<flow_http_port> weight=5 max_fails=2 fail_timeout=60s;
    server <flow_server_ip2>:<flow_http_port> weight=5 max_fails=2 fail_timeout=60s;
}

server {
    listen <nginx_grpc_port> http2;
    server_name <nginx_server_ip>;
    location / {
        proxy_pass grpc://grpc_backend;
    }
}

server {
    listen <nginx_http_port>;
    server_name <nginx_server_ip>;
    location / {
        proxy_pass http://http_backend;
    }
}
~~~

#### 3. FATE 部署

高可用FATE Flow环境可以通过先部署一套完整FATE环境的基础上额外单独部署一个或多个FATE Flow。

完整版FATE环境部署请参考：https://github.com/FederatedAI/AnsibleFATE/blob/main/docs/ansible_deploy_FATE_manual.md

##### 3.1 完整FATE服务配置修改

在部署完成zookeeper, Nginx,  FATE后(**本示例zk, nginx，完整FATE服务都部署于同一机器**）, FATE需要修改conf/service_conf.yaml配置以及eggroll/conf/route_table.json

a. 开启 use_registry 并配置 zookeeper

b. 开启 enable_model_store 并配置 model_store_address

c. 配置 fateflow.nginx，填入 nginx 或其他 web server 的 IP 和端口

d. 修改路由表配置，指向nginx所在服务IP, grpc 端口

conf/service_conf.yaml参考配置如下

~~~
use_registry: true    # 注册口
fateflow:
  host: 192.168.0.1  
  http_port: 9380
  grpc_port: 9360
  nginx:               # 配置 fateflow.nginx
    host: 192.168.0.1  # 部署有nginx 服务ip
    http_port: 9998    # nginx实际监听的http端口
    grpc_port: 9999     # nginx实际监听的grpc端口
database:
  name: fate_flow
  user: fate
  passwd: fate_deV2999
  host: 192.168.0.1      # 完整FATE服务ip
  port: 3306
  max_connections: 100
  stale_timeout: 30
zookeeper:
  hosts:
  - 192.168.0.1:2181  # 部署有zk的ip(本示例zk与完整FATE服务部署在同一机器)
  use_acl: True       # 开启的注册口
  user: fate
  password: fate
# engine services
fate_on_eggroll:
  rollsite:
    host: 192.168.0.1  # 使用完整FATE服务的ip
    port: 9370
enable_model_store: true   # 模型存储开关 
model_store_address
  storage: mysql      # 使用mysql 
  database: fate_flow  # 数据库名
  user: fate
  password: fate_deV2999    # 密码
  host: 192.168.0.1       # 完整FATE服务ip
  port: 3306
  max_connections: 10
  stale_timeout: 10
~~~

eggroll/conf/route_table.json参考配置如下

~~~
# route_table.json

{
  "route_table":
  {
    "default":
    {
      "default":[
        {
          "ip": "192.168.0.3",   # exchange或者对端ip
          "port": 9370
        }
      ]
    },
    "10000":
    {
      "default":[
        {
          "ip": "192.168.0.1",
          "port": 9370
        }
      ],
      "fateflow":[
        {
          "ip": "192.168.0.1",   # 指向nginx所在ip
          "port": 9999           # nginx监听的grpc端口
        }
      ]
    }
  },
  "permission":
  {
    "default_allow": true
  }
}
~~~

~~~
# 重启 fate_flow 服务
sh /data/projects/common/supervisord/service.sh restart fate-fateflow

# 重启 rollsite 服务
sh /data/projects/common/supervisord/service.sh restart fate-rollsite
~~~

##### 3.2 FATE FLow集群服务部署

**注：本示例建立在一个完整的FATE服务，zk服务，nginx服务基础上**

AnsibleFATE在部署fate_flow时，bash deploy/deploy.sh init 后修改 deploy/conf/setup.conf 

参考配置如下

~~~
#moduel list: mysql|eggroll|fate_flow|fateboard
modules:        #需要部署的模块            
  - eggroll
  - fate_flow
#
#role list: host|guest|exchange
roles:
  - host:10000
#
#ssl role list: host && guest | host&&exchange | guest&&exchange 
ssl_roles: []
#
polling: {}
#host ip lists
#host_ips: [ "default:192.168.0.1", "rollsite:192.168.0.1", "nodemanager:192.168.0.1|192.168.0.2", "clustermanager:192.168.0.1", "fate_flow:192.168.0.1", "fateboard:192.168.0.1" ]
host_ips:
  - default:192.168.0.2    # 需要部署的ip

~~~

修改完配置后执行  render 

~~~
sh deploy/deploy.sh render
~~~

render后生成一系列ansible部署配置，按需修改配置（已host为例）参考配置如下：

~~~
vi var_files/prod/fate_host
~~~

~~~
host:
  partyid: 10000
  rollsite:
    enable: true
    coordinator: fate
    ips:
      - 192.168.0.2    # 部署机的ip
    port: 9370
    secure_port: 9371
    server_secure: false
    client_secure: false
    polling:
      enable: false
    route_tables:
      - id: default
        routes:
          - name: default
            ip: 192.168.0.3  # 写对端ip或者exchange的ip  
            port: 9370
            is_secure: false
      - id: 10000
        routes:
          - name: default
            ip: 192.168.0.1  # 写完整FATE的ip
            port: 9370
            is_secure: false
          - name: fateflow
            ip: 192.168.0.1  # 写部署nginx的ip (本示例nginx与完整FATE服务部署在同一机器)
            port: 9999       # nginx的grpc监听端口
  clustermanager:
    enable: true
    ips:
      - 192.168.0.1         # 写完整FATE的ip
    port: 4670
    cores_per_node: 16
  nodemanager:
    enable: true
    ips:
      - 192.168.0.1        # 写完整FATE的ip
    port: 4671
  eggroll:
    dbname: eggroll_meta
    egg: 4
  fate_flow:
    enable: true
    ips:
      - 192.168.0.2      # 写部署机ip
    grpcPort: 9360
    httpPort: 9380
    dbname: fate_flow
    proxy: rollsite
    http_app_key:
    http_secret_key:
    use_deserialize_safe_module: false
    default_engines: eggroll
  fateboard:
    enable: false
    ips:
      - 192.168.0.2
    port: 8080
    dbname: fate_flow
  mysql:
    enable: false      
    type: outside       # 没有部署mysql, 所以使用完整FATE的mysql
    ips:
      - 192.168.0.1     # 写完整FATE的ip
    port: 3306
    dbuser: fate
    dbpasswd: fate_deV2999
  zk:
    enable: true         # 默认false,已有zk服务可修改为true
    lists:
      - ip: 192.168.0.1  # 部署有zk的ip(本示例zk与完整FATE服务部署在同一机器)
        port: 2181
    use_acl: true       # 默认false, 已有zk服务可修改为true
    user: fate
    passwd: fate
  servings:
    ips:
      - 127.0.0.1
    port: 8000
  model_store:
    enable: true
    storage: mysql
    
~~~

执行部署

~~~
sh deploy/deploy.sh deploy
~~~



##### 3.3 FATE Flow配置修改

同一方下的多个 flow 实例的配置应相同，它们共享使用同一个 mysql 和 zookeeper

**注意： 如按上面步骤来的，已有了zk,nginx， 只需修改最后d,e两项配置**

a. 修改 conf/service_conf.yaml：

b. 开启 use_registry 并配置 zookeeper

c. 开启 enable_model_store 并配置 model_store_address

d. **配置 fateflow.nginx，填入 nginx 或其他 web server 的 IP 和端口**

e. **修改fate_on_eggroll.rollsit  ip, 共享使用同一个rollsit**



参考配置如下

~~~
use_registry: true    # 注册口
fateflow:
  host: 192.168.0.2   # 高可用fateflow ip(部署机ip)
  http_port: 9380
  grpc_port: 9360
  nginx:               # 配置 fateflow.nginx
    host: 192.168.0.1  # 部署有nginx 服务ip
    http_port: 9998    # nginx实际监听的http端口
    grpc_port: 9999     # nginx实际监听的grpc端口
  database:
  name: fate_flow
  user: fate
  passwd: fate_deV2999
  host: 192.168.0.1      # 完整FATE服务ip
  port: 3306
  max_connections: 100
  stale_timeout: 30
zookeeper:
  hosts:
  - 192.168.0.1:2181  # 部署有zk的ip(本示例zk与完整FATE服务部署在同一机器)
  use_acl: True       # 开启的注册口
  user: fate
  password: fate
fate_on_eggroll:
  rollsite:
    host: 192.168.0.1  # 使用完整FATE服务的ip
    port: 9370
  clustermanager:
    cores_per_node: 16
    nodes: 1
fateboard:
  host: 192.168.0.1  #本机未部署可忽略
  port: 8080

enable_model_store: true   # 模型存储开关 
model_store_address
  storage: mysql      # 使用mysql 
  database: fate_flow  # 数据库名
  user: fate
  password: fate_deV2999    # 密码
  host: 192.168.0.1       # 完整FATE服务ip
  port: 3306
  max_connections: 10
~~~

##### 3.4 eggroll配置

如果一直按上文执行， eggroll路由配置可不修改， 参考配置如下（2边高可用的都一致）

###### 3.4.1路由表配置参考

eggroll/conf/route_table.json

~~~
# route_table.json

{
  "route_table":
  {
    "default":
    {
      "default":[
        {
          "ip": "192.168.0.3",   # exchange或者对端ip
          "port": 9370
        }
      ]
    },
    "10000":
    {
      "default":[
        {
          "ip": "192.168.0.1",
          "port": 9370
        }
      ],
      "fateflow":[
        {
          "ip": "192.168.0.1",   # 指向nginx所在ip
          "port": 9999           # nginx监听的grpc端口
        }
      ]
    }
  },
  "permission":
  {
    "default_allow": true
  }
}

~~~

###### 3.4.2 eggroll.properties配置参考
eggroll/conf/eggroll.properties   需修改eggroll.rollsite.host 为完整FATE服务的ip

~~~
# eggroll.properties

# for roll site. rename in the next round
eggroll.rollsite.coordinator=fate
eggroll.rollsite.host=192.168.0.1     # 注意修改
~~~

关闭fate_rollsite服务并重启 fate_flow 服务即可

~~~
# 关闭fate_rollsite服务
sh /data/projects/common/supervisord/service.sh stop fate-rollsite

# 重启 fate_flow 服务
sh /data/projects/common/supervisord/service.sh restart fate-fateflow
~~~

#####  4. 验证

######  4.1  高可用机器均可以发起任务

~~~
# 发起toy 任务
source /data/projects/fate/bin/init_env.sh 
flow test toy -gid 9999 -hid 10000
~~~

###### 4.2 停止高可用一方服务， 另一方也可以正常发起

~~~
# stop 一方fate_flow 服务
sh /data/projects/common/supervisord/service.sh stop fate-fateflow

# 在另一台机器上发起toy 任务
source source /data/projects/fate/bin/init_env.sh 
flow test toy -gid 9999 -hid 10000
~~~





