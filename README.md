[中文](./README_zh.md)

## Overview

AnsibleFATE deploys FATE clusters via Ansible. AnsibleFATE provides scripts to optimize the process of deployment configuration. It helps users to quickly complete the deployment operations.

## Download

See [wiki](https://github.com/FederatedAI/FATE/wiki/Download).

## Project structure

````
AnsibleFATE
|-- docs
|-- environments
|-- logs
|-- roles
|-- deploy
|-- var_files
````

Description:

   - docs: Documentation directory.

   - environments: Configuration files for the ansbile deployment on the target host.

   - logs: The directory of the deployment logs.

   - roles: Ansible deployment modules.

   - deploy: Deployment scripts and configuration files

   - var_files: Ansible configuration files



## Features

- Optimized the deployment configuration.
- Customizable deployment of the clusters: a combination of different backend engines and components.
- Multiple deployment methods for all or some of FATE's modules.
- Provides both the online and offline deployment packages.



## Documentation

- [Deployment Guide](docs/ansible_deploy_FATE_manual.md)
- [FAQ](docs/ansible_deploy_fate_FAQ.md)

## License
[Apache License 2.0](LICENSE)
