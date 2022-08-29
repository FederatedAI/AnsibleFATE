## 部署fate集群的后置操作

### 1 概述

​     本文介绍在部署fate集群之前执行的一系列后置操作。

​     示例操作用户：超级用户root、有sudo权限用户 和普通权限用户app

​      示例操作主机：192.168.0.1





### 2 增加虚拟内存

本节适用场景：后端引擎使用eggroll

示例操作用户： root（或有sudo权限用户）

**示例操作主机：192.168.0.1 **

示例需求：

​         生产环境使用时，因内存计算需要增加128G虚拟内存。

示例操作前提：需检查存储空间是否足够。

示例操作：

- 方法1

```
cd /data
dd if=/dev/zero of=/data/swapfile128G bs=1024 count=134217728
mkswap /data/swapfile128G
swapon /data/swapfile128G
cat /proc/swaps
echo '/data/swapfile128G swap swap defaults 0 0' >> /etc/fstab
```

- 方法2：使用ansible部署包中的脚本

```
bash /data/projects/fate/tools/makeVirtualDisk.sh
Waring: please make sure has enough space of your disk first!!! （请确认有足够的存储空间）
current user has sudo privilege(yes|no):yes      （是否有sudo权限，输入yes，不能简写）
Enter store directory:/data    （设置虚拟内存文件的存放路径，确保目录存在和不要设置在根目录）
Enter the size of virtual disk(such as 64G/128G):128G  （设置虚拟内存文件的大小，32G的倍数，数字后要带单位G，一般设置为128G即可）
/data 32 1
32768+0 records in
32768+0 records out
34359738368 bytes (34 GB) copied, 200.544 s, 171 MB/s
Setting up swapspace version 1, size = 33554428 KiB
no label, UUID=58ce153c-feac-4989-b684-c100e4edca0b
/data 32 2
32768+0 records in
32768+0 records out
34359738368 bytes (34 GB) copied, 200.712 s, 171 MB/s
Setting up swapspace version 1, size = 33554428 KiB
no label, UUID=d44e27ed-966b-4477-b46e-fcda4e3057c2
/data 32 3
32768+0 records in
32768+0 records out
34359738368 bytes (34 GB) copied, 200.905 s, 171 MB/s
Setting up swapspace version 1, size = 33554428 KiB
no label, UUID=ab5db8d7-bc09-43fb-b23c-fc11aef1a3b6
/data 32 4
32768+0 records in
32768+0 records out
34359738368 bytes (34 GB) copied, 201.013 s, 171 MB/s
Setting up swapspace version 1, size = 33554428 KiB
no label, UUID=c125ede3-7ffd-4110-9dc8-ebdf4fab0fd1
```

示例操作结果校验：

```
cat /proc/swaps

Filename                                Type            Size    Used    Priority
/data/swapfile32G_1                     file            33554428        0       -1
/data/swapfile32G_2                     file            33554428        0       -2
/data/swapfile32G_3                     file            33554428        0       -3
/data/swapfile32G_4                     file            33554428        0       -4

free -m
              total        used        free      shared  buff/cache   available
Mem:          15715        6885          91         254        8739        8461
Swap:        131071           0      131071

```



### 3 清理部署临时目录

```
bash /data/projects/tools/clean_tmp.sh
```
