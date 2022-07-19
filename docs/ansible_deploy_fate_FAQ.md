# ansible 部署FATE集群FAQ

- Q1:  如何绕过sudo？

```
vim project_prod.yaml
 #- base	--注释base行

若绕过sudo，需要提前执行安装系统依赖脚本(使用root或者sudo安装)
/bin/bash tools/install_base.sh
```

- Q2: 如何绕过环境检查？

​		为了方便测试，系统参数可能不会与生产同步，需要跳过环境检查的报错

```
vim var_files/prod/base_init
envCheck: False		--设置为False
```
