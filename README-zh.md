# AnsibleFATE

**Note**: The `master` branch may be in an *unstable* or *even broken* state during development. Please use [releases](https://github.com/FederatedAI/KubeFATE/releases) instead of the `master` branch in order to get a stable set of binaries.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview



FATE (Federated AI Technology Enabler) 是微众银行AI部门发起的开源项目，为联邦学习生态系统提供了可靠的安全计算框架。FATE项目使用多方安全计算 (MPC) 以及同态加密 (HE) 技术构建底层安全计算协议，以此支持不同种类的机器学习的安全计算，包括逻辑回归、基于树的算法、深度学习和迁移学习等。

Ansible是一个IT自动化工具。它可以配置系统，部署软件，并编排更高级的的IT任务，如持续部署或零停机滚动更新。

 AnsibleFATE  支持通过Ansible进行部署fate集群。我们提供了辅助脚本，优化部署配置的过程，有助于用户快速完成部署操作。部署是一件简单的事。



## Getting Involved

- For any frequently asked questions, you can check in [FAQ](docs/ansible_deploy_fate_FAQ.md).
- Please report bugs by submitting [issues](https://github.com/FederatedAI/AnsibleFATE/issues).
- Submit contributions using [pull requests](https://github.com/FederatedAI/AnsibleFATE/pulls)

## Project Structure

```
AnsibleFATE
|-- build
|-- docs
|-- environments
|-- logs
|-- roles
|-- deploy
|-- var_files
```



说明：

   - build: 构建目录。使用辅助脚本和配置文件，按需构建产品的部署包。

   -   docs: 文档目录。

   - environments： ansbile部署的目标主机配置文件

   - logs： 部署日志目录

   - roles： ansible部署模块

   - deploy： 部署辅助脚本和配置文件

   - var_files: ansible配置文件

     

### Major features of new AnsibleFATE

- 优化部署配置体验，支持多个产品使用一致的风格进行部署。
- 支持多种形态的部署： 针对产品的全部或部分模块的多种部署方式。
- 提供在线和离线2种部署包，可按需使用。
- 提供从源码到输出部署离线包的打包脚本。



## 部署文档

- [部署手册](docs/ansible_deploy_FATE_manual.md)

- [场景部署示例： 部署一方](docs/ansible_deploy_one_side.md)

- [场景部署示例： 部署二方](docs/ansible_deploy_two_sides.md)

- [场景部署示例： 部署三方](docs/ansible_deploy_three_sides.md)





## License

Apache License 2.0