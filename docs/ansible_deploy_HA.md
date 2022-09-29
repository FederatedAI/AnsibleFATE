# Ansible 部署 FATE 高可用集群

## 概述

从 FATE 1.9 开始，Flow 支持每一方同时运行多个 Flow 服务以实现负载均衡和故障转移

## 依赖

- [Apache ZooKeeper](https://zookeeper.apache.org)

- [Nginx](https://www.nginx.com) 或其他支持 HTTP 和 GRPC 负载均衡的 web server

## 部署

AnsibleFATE 可在每一方同时部署多套环境，`bash deploy/deploy.sh init` 后修改 `deploy/conf/setup.conf` 即可

如生成的配置如下：

```
host_ips:
  - default:192.168.0.1

guest_ips:
  - default:192.168.1.1
```

可修改为：

```
host_ips:
  - default:192.168.0.1
  - fate_flow:192.168.0.1|192.168.0.2

guest_ips:
  - default:192.168.1.1
  - fate_flow:192.168.1.1|192.168.1.2
```


## 配置

### Flow

同一方下的多个 flow 实例的配置应相同，它们共享使用同一个 mysql 和 zookeeper

修改 `conf/service_conf.yaml`：

- 开启 `use_registry` 并配置 `zookeeper`

- 开启 `enable_model_store` 并配置 `model_store_address`

- 配置 `fateflow.nginx`，填入 nginx 或其他 web server 的 IP 和端口

### Nginx

同一方下只需一个 nginx 实例

请自行部署 nginx 并配置负载均衡，以下是一份基本示例，不建议直接在生存环境使用：

```
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
```

### Rollsite

同一方下只需一个 rollsite 实例

修改 `eggroll/conf/route_table.json`：

- 有 exchange 的情况下，只需修改本方 party_id 下的 IP 和端口，指向 nginx 所在服务器的 IP、nginx 监听的 GRPC 端口

- 没有 exchange 的情况下，需同时修改本方 party_id 和 `default` （指向对端）下的 IP 和端口

### Exchange（如有）

Exchange 是指 role 为 exchange 的 rollsite，exchange 上的 `route_table.json` 不需要修改，因为 party_id 下的 IP 和端口指向各方的 rollsite
