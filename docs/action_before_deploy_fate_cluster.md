## 部署fate集群的前置操作

### 1 概述

​     本文介绍在部署fate集群之前执行的一系列前置操作。

​      示例操作机器：192.168.0.1

​      示例操作用户：超级用户root 



### 2 hostname配置

#### **2.1 修改主机名**

**在192.168.0.1 root用户下执行：**

hostnamectl set-hostname VM_0_1_centos

#### **2.2 加入主机映射**

**在目标服务器（192.168.0.1）root用户下执行：**

vim /etc/hosts

192.168.0.1 VM_0_1_centos

### 3 关闭selinux  

**在目标服务器（192.168.0.1）root用户下执行：**

确认是否已安装selinux

centos系统执行：rpm -qa | grep selinux

ubuntu系统执行：apt list --installed | grep selinux

如果已安装了selinux就执行：setenforce 0



### 4 修改Linux系统参数

**在目标服务器（192.168.0.1）root用户下执行：**

1）vim /etc/security/limits.conf

\* soft nofile 65535

\* hard nofile 65535

2）vim /etc/security/limits.d/20-nproc.conf

\* soft nproc unlimited

### 5 关闭防火墙

**在目标服务器（192.168.0.1）root用户下执行**

如果是Centos系统：

systemctl disable firewalld.service

systemctl stop firewalld.service

systemctl status firewalld.service

如果是Ubuntu系统：

ufw disable

ufw status

### 6 软件环境初始化

**在目标服务器（192.168.0.1）root用户下执行**

#### **6.1 创建用户**

```
groupadd apps
useradd -s /bin/bash -g apps -d /home/app app
passwd app
```

6.2 建立目录

```
mkdir -pv /data/projects /data/temp /data/logs
chown -R app:apps /data/projects /data/temp /data/logs
```

