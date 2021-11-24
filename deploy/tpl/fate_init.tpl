
deploy_mode: ${deploy_mode}
pname: ${pname}

deploy_roles: []
key_roles: []
 
mversion: 1.6.1
versions:
  fate_flow: 1.6.1
  eggroll: 1.6.1
  fateboard: 1.6.1

python:
  version: 4.5.4
  dest: "miniconda3"
  venv: "common/python/venv"
  pip: pip-packages-fate-1.6.1
  must:
  - setuptools-42.0.2-py2.py3-none-any.whl
java:
  name: "jdk"
  version: "8u192"
  path: "common/jdk"
mysql:
  version: "8.0.13"
  path: "common/mysql"
  user: "root"
  passwd: "fatE168dev"
redis:
  version: "5.0.2"
  path: "common/redis"
rabbitmq:
  version: "3.6.15"
  path: "common/rabbitmq"
