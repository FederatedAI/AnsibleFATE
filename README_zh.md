# AnsibleFATE

## 总览

AnsibleFATE 支持通过 Ansible 进行部署 FATE 集群。我们提供了辅助脚本，优化部署配置的过程，有助于用户快速完成部署操作。

## 下载

参见 [wiki](https://github.com/FederatedAI/FATE/wiki/Download)。

## 项目结构

```
AnsibleFATE
|-- docs
|-- environments
|-- logs
|-- roles
|-- deploy
|-- var_files
```

说明：

   - docs: 文档目录。

   - environments： ansbile部署的目标主机配置文件

   - logs： 部署日志目录

   - roles： ansible部署模块

   - deploy： 部署辅助脚本和配置文件

   - var_files: ansible配置文件



## AnsibleFATE 主要功能

- 优化部署配置体验，支持产品使用一致的风格进行部署。
- 支持按需选择组合部署集群： 不同后端引擎和不同组件。
- 支持多种形态的部署： 针对产品的全部或部分模块的多种部署方式。
- 提供在线和离线2种部署包，可按需使用。



## 部署文档

- [部署手册](docs/ansible_deploy_FATE_manual.md)

- 场景部署示例

  - [示例一： 部署一方](docs/ansible_deploy_one_side.md)

  - [示例二： 部署二方](docs/ansible_deploy_two_sides.md)

  - [示例三： 部署三方](docs/ansible_deploy_three_sides.md)



## 了解更多

- [FAQ](docs/ansible_deploy_fate_FAQ.md).
- [issues](https://github.com/FederatedAI/AnsibleFATE/issues).
- [pull requests](https://github.com/FederatedAI/AnsibleFATE/pulls)

## License
[Apache License 2.0](LICENSE)
