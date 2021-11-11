#!/bin/bash

set -euo pipefail

################################  请根据实际情况修改以下参数  ################################
FATE_ROOT=/data/projects
LOG_ROOT=/data/logs
TEMP_ROOT=/data/temp
DEPLOY_USER=app
DEPLOY_GROUP=apps
################################  请根据实际情况修改以上参数  ################################


#new base
echo "mkdir new base directory"
mkdir -p ${FATE_ROOT} ${LOG_ROOT} ${TEMP_ROOT}
chown -R ${DEPLOY_USER}:${DEPLOY_GROUP} ${FATE_ROOT} ${LOG_ROOT} ${TEMP_ROOT}

#install dependencies
system=`sed -e '/"/s/"//g' /etc/os-release | awk -F= '/^NAME/{print $2}'`
echo ${system}
case "${system}" in
    "CentOS Linux")
            echo "CentOS System"
            yum -y install gcc gcc-c++ make openssl-devel gmp-devel mpfr-devel libmpc-devel libaio numactl autoconf automake libtool libffi-devel snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel lz4-devel libasan lsof telnet psmisc iperf3 python-setuptools
            ;;
    "Ubuntu")
            echo "Ubuntu System"
            apt-get install -y gcc g++ make openssl libgmp-dev libmpfr-dev libmpc-dev libaio1 libaio-dev numactl autoconf automake libtool libffi-dev libssl1.0.0 libssl-dev liblz4-1 liblz4-dev liblz4-1-dbg liblz4-tool zlib1g zlib1g-dbg zlib1g-dev telnet psmisc iperf3 python-setuptools
            cd /usr/lib/x86_64-linux-gnu
            if [ ! -f "libssl.so.10" ];then
                 sudo ln -s libssl.so.1.0.0 libssl.so.10
                 sudo ln -s libcrypto.so.1.0.0 libcrypto.so.10
            fi
            ;;
    *)
            echo "Not support this system."
            exit -1
esac
