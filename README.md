[中文](./README_zh.md)

## Overview

AnsibleFATE deploys FATE clusters via Ansible. AnsibleFATE provides scripts to optimize the process of deployment configuration. It helps users to quickly complete the deployment operations.

## Project structure

````
AnsibleFATE
|-- build
|-- docs
|-- environments
|-- logs
|-- roles
|-- deploy
|-- var_files
````

Description:

   - build: the build directory. It contains helper scripts and configuration files to build deployment packages.

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
- Provides packaging scripts for building the offline packages from source code.


## Documentation

- [Deployment Guide](docs/ansible_deploy_FATE_manual.md)
- [FAQ](docs/ansible_deploy_fate_FAQ.md)

## License
[Apache License 2.0](LICENSE)
