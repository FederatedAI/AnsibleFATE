

# ansible 部署FATE集群FAQ





- Q1:  如何绕过sudo？

```
vi project_prod.yaml
 #- base	--注释base行
```

- Q2: 如何绕过环境检查？

​		为了方便测试，系统参数可能不会与生产同步，需要跳过环境检查的报错

```
vi var_files/prod/base_init
envCheck: False		--设置为False
```

