#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
cd $workdir

url="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com"

eversion=2.4.0

def_assist_mode() {
  local args=( $@ )
  echo "def_assist_mode: ${args[*]}"
  if [ ${#args[*]} == 0 ]; then
    args=( "--help" )
  fi
  version=""
  minversion=""
  package_type="local"
  package_dir=""
  is_archive=false
  for arg in ${args[*]};
  do
    case ${arg%=*} in
      "--version")
        version=${arg#*=}
      ;;
    
      "--minversion")
        minversion=${arg#*=}
      ;;

      "--type")
        package_type=${arg#*=}
      ;;

      "--dir")
        if [ "${arg#*=}" == "${arg%=*}" -o ${arg#*=} == "--dir" ]; then
          echo -e "Error: no package_dir information\n"
          exit 1
        else
          package_dir=${arg#*=}
        fi
      ;;

      "--archive")
        is_archive=true
      ;;

      "--help")
        echo "Usage: $0 --version|--minversion|--type|--dir|--archive"
        echo "     args:  "
        echo "         --version=1.7.0"
        echo "         --minversion=release"
        echo "         --type=online or local(default)"
        echo "         --dir=/data/temp"
        echo "         --archive"
        echo ""
        exit 1
      ;;
      *)
        echo "arg: $arg wrong"
        echo "Usage: $0 --version|--minversion|--type|--dir|--help"
        echo ""
        exit 1
      ;;
    esac
  done

  if [ -z "$version" ]; then
    echo -e "Error: no version information, please input --version=\n"
    exit 1
  fi

  if [ -n "$minversion" ]; then
    fname="FATE_install_${version}_${minversion}.tar.gz"
  else
    echo -e "Error: no minversion information, please input --minversion=\n"
    exit 1
  fi

}


function_copy() {
  mv fateboard.tar.gz fateboard-${version}-${minversion}.tar.gz
  mv eggroll.tar.gz eggroll-${eversion}-release.tar.gz
  mv examples.tar.gz fate_examples-${version}-${minversion}.tar.gz
  mv fateflow.tar.gz fateflow-${version}-${minversion}.tar.gz
  mv fate.tar.gz fate-${version}-${minversion}.tar.gz
  cp -v fateboard-${version}-${minversion}.tar.gz ${workdir}/../roles/fateboard/files/ -f
  cp -v eggroll-${eversion}-release.tar.gz ${workdir}/../roles/eggroll/files/ -f
  cp -v fate_examples-${version}-${minversion}.tar.gz fateflow-${version}-${minversion}.tar.gz fate-${version}-${minversion}.tar.gz RELEASE.md fate.env ${workdir}/../roles/fateflow/files/ -f
  cp -v pypi.tar.gz requirements.txt ${workdir}/../roles/python/files/ -f
  cp -v build.tar.gz deploy.tar.gz ${workdir}/../roles/check/files/ -f
  tar xf jdk.tar.gz
  cp -v jdk/jdk-8u192.tar.gz ${workdir}/../roles/java/files/ -f
}

function_archive() {
  basedir="${workdir}/.."
  cd $basedir/..
  tempdir=`pwd`
  if [ -n "${package_dir}" ]; then
    tar -czf ${package_dir}/AnsibleFATE_${version}_${minversion}-offline.tar.gz --exclude=logs AnsibleFATE
    echo -e "\nThe fate offline  package is stored in the ${package_dir}/AnsibleFATE_${version}-${minversion}_offline.tar.gz"
  else
    mkdir -p packages
    tar -czf packages/AnsibleFATE_${version}_${minversion}-offline.tar.gz --exclude=logs AnsibleFATE
    echo -e "\nThe fate offline  package is stored in the ${tempdir}/packages/AnsibleFATE_${version}_${minversion}-offline.tar.gz"
  fi
}

function_download() {
  mysql="mysql-8.0.13.tar.gz"
  python="fate_python.tar.gz"
  supervisor="fate_supervisor.tar.gz"
  rabbitmq="rabbitmq-server-generic-unix-3.6.15.tar"
  if [ ! -f ${workdir}/../roles/python/files/setuptools-50.3.2-py3-none-any.whl ]; then
    echo "-------------Download python package-----------"
    echo "wget -P ${workdir}/../roles/python/files/ ${url}/fate/${version}/${minversion}/${python}"
    wget -P ${workdir}/../roles/python/files/ ${url}/fate/${version}/${minversion}/${python}
    tar xf ${workdir}/../roles/python/files/${python} -C ${workdir}/../roles/python/files/
    rm ${workdir}/../roles/python/files/${python}
  fi
  if [ ! -f ${workdir}/../roles/mysql/files/$mysql ]; then
    echo "-------------Download mysql package---------"
    echo "wget -P ${workdir}/../roles/mysql/files/ ${url}/${mysql}"
    wget -P ${workdir}/../roles/mysql/files/ ${url}/${mysql}
  fi
  if [ ! -f ${workdir}/../roles/supervisor/files/supervisord-conf-1.1.4.tar.gz ]; then
    echo "-------------Download supervisor package-----------"
    echo "wget -P ${workdir}/../roles/supervisor/files/ ${url}/${supervisor}"
    wget -P ${workdir}/../roles/supervisor/files/ ${url}/${supervisor}
    tar xf  ${workdir}/../roles/supervisor/files/${supervisor} -C  ${workdir}/../roles/supervisor/files/
    rm ${workdir}/../roles/supervisor/files/${supervisor}
  fi
  if [ ! -f ${workdir}/../roles/rabbitmq/files/$rabbitmq ]; then
    echo "-------------Download rabbitmq package-----------"
    echo "wget -P ${workdir}/../roles/rabbitmq/files/ ${url}/${rabbitmq}"
    wget -P ${workdir}/../roles/rabbitmq/files/ ${url}/${rabbitmq}
  fi
}

function_check() {
  packages_md5=()
  value=`cat packages_md5.txt`
  for name in "bin" "conf" "build" "deploy" "fate" "fateflow" "examples" "fateboard" "eggroll" "jdk" "pypi" "proxy" "python36"
  do
    package_name=$name".tar.gz"
    package_md5=`md5sum ${package_name} |awk '{print $1}'`
    packages_md5=( ${packages_md5[*]} $name':'$package_md5 )
   done
  declare -a result_list
  t=0
  flag=0
  for m in ${packages_md5[@]};do
    for n in ${value[*]};do
      if [ "$m" = "$n" ];then
        echo -e "The $m md5 value matches successfully\n"
        flag=1
        break
      fi
    done
    if [ $flag -eq 0 ]; then
      result_list[t]=$m
      t=$((t+1))
    else
      flag=0
    fi
  done
  if [[ -n $result_list ]];then
    echo -e "The ${result_list[*]} md5 value matches failed\n"
    exit 1
  fi
}

function_package() {
  tar xf $fname
  cd FATE_install_${version}_${minversion};
  function_check
  function_copy
  function_download
}

function_main() {
  local dir=$1
  if [ ! -f ${dir}/$fname ]; then
    echo -e "${dir}/$fname not exists\n"
    exit 1
  else
    cd ${dir}
    function_package
    cd ${dir} && rm -rf $fname FATE_install_${version}_${minversion}
    if [ "${is_archive}" == "true" ]; then
      function_archive
    fi
  fi
}

def_main_process() {
  def_assist_mode $@

  case ${package_type} in
    "online")
        echo "---------------Download $fname---------------"
        if [ -z "$package_dir" ]; then
          wget -P ${workdir} ${url}/${fname}
          function_main ${workdir}
        else
          wget -P ${package_dir} ${url}/${fname}
          function_main ${package_dir}
        fi
    ;;

    "local")
      if [ -n "$package_dir" ]; then
        function_main ${package_dir}
      else
        echo -e "Package file path not specified, please input --dir=\n"
        exit 1
      fi
    ;;
  
    *)
      echo "arg: $package_type wrong"
      echo "Usage: --type=local or online"
      echo ""
    ;;
  esac
}

args=()
until [ -z "$1" ]
do
  args=( ${args[*]} "$1" )
  shift
done

if [ "${#args[*]}" == 0 ]
then
  args=( "--help" )
fi

def_main_process ${args[*]}
