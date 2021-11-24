#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
cd $workdir
chmod a+x ./bin/*

init() {
  [ ! -d ./conf ] && mkdir ./conf
  if [ "$#" -lt 1 ]; then
    echo "$0 pname [version] [minversion] "
    exit 1;
  fi
  pname=$1
  case $# in 
    3)

      version=$2
      minversion=$3
      if [ "$minversion" == "release" ]
      then
        version="${version}"
      else
        version="${version}-${minversion}"
      fi
    ;;

    2)
      version=$2
    ;;
   
    1)
      version=$( ${workdir}/bin/yq eval '.'"$pname"'|keys|.[0]' ${workdir}/files/fate_product_versions.yml)
    ;;
 
    *)
      echo "$0 init pname [version] [minversion] "
    ;; 
  esac
  echo "$pname: $version"
  isHas=$( ${workdir}/bin/yq eval '.'"$pname"'|has("'"$version"'")' ${workdir}/files/fate_product_versions.yml)
  if [ "$isHas" != "true" ]
  then
    echo "Warning: not support $pname version: ${version}"
    return
  fi
  for name in $( ${workdir}/bin/yq eval '.'"$pname"'."'"$version"'"|keys|.[]' ${workdir}/files/fate_product_versions.yml); do
    tversion=$( ${workdir}/bin/yq eval '.'"$pname"'."'"$version"'".'"$name"'[0]' ${workdir}/files/fate_product_versions.yml )
    if [ "${tversion%-*}" == "${tversion#*-}" ]; then
      eval ${name}_version="${tversion}-release"
    else
      eval ${name}_version="${tversion}"
    fi
  done
  {
  echo "project: $pname"
  echo "products:"
  echo "- fate"
  echo "- eggroll"
  echo "product_fate_version: ${version}"
  echo "product_fate_versions:"
  echo "  fateflow: ${fateflow_version}"
  echo "  fateboard: ${fateboard_version}"
  echo "  eggroll: ${eggroll_version}"
  } > conf/setup.conf
}

get_pinfo() {
  project=$( ${workdir}/bin/yq eval '.project' ${workdir}/conf/setup.conf )
  products=( $( ${workdir}/bin/yq eval '.products.[]' ${workdir}/conf/setup.conf ) )

  echo "project: $project"
  echo "products: ${products[*]}"

  product_fate_version=$( ${workdir}/bin/yq eval '.product_fate_version' ${workdir}/conf/setup.conf )
  echo "fate_version: $product_fate_version"
}


download() {
  url="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com"
  mysql="mysql-8.0.13.tar.gz"
  python="fate_python.tar.gz"
  supervisor="fate_supervisor.tar.gz"
  rabbitmq="rabbitmq-server-generic-unix-3.6.15.tar" 
  if [ ! -f ${workdir}/../roles/python/files/setuptools-50.3.2-py3-none-any.whl ]; then
    echo "-------------Download python package-----------"
    echo "wget -P ${workdir}/../roles/python/files/ ${url}/${python}"
    wget -P ${workdir}/../roles/python/files/ ${url}/${python}
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

  echo "-------------Download $project package-----------"
  if [ "${product_fate_version%-*}" == "${product_fate_version#*-}" ]; then
    purl="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/$project/${product_fate_version}/release"
  else
    purl="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/$project/${product_fate_version/-//}"
  fi

  if [ ! -f ../roles/python/files/pypi.tar.gz -o ! -f ../roles/python/files/requirements.txt ]; then
     curl ${purl}/requirements.txt -o ../roles/python/files/requirements.txt
     curl ${purl}/pypi.tar.gz -o ../roles/python/files/pypi.tar.gz
  fi

  if [ ! -f ../roles/check/files/deploy.tar.gz -o ! -f ../roles/check/files/build.tar.gz ]; then
    curl ${purl}/deploy.tar.gz -o ../roles/check/files/deploy.tar.gz
    curl ${purl}/build.tar.gz -o ../roles/check/files/build.tar.gz
  fi

  if [ ! -f ../roles/java/files/jdk-8u192.tar.gz ]; then
    curl ${purl}/jdk.tar.gz -o ../roles/java/files/jdk.tar.gz
    tar xf ../roles/java/files/jdk.tar.gz -C ../roles/java/files/
    cp ../roles/java/files/jdk/jdk-8u192.tar.gz ../roles/java/files/
    rm -rf ../roles/java/files/jdk.tar.gz ../roles/java/files/jdk
  fi

  for name in $( ${workdir}/bin/yq eval '.product_fate_versions|keys|.[]' ${workdir}/conf/setup.conf); do
    fversion=$( ${workdir}/bin/yq eval '.product_fate_versions.'"$name"'' ${workdir}/conf/setup.conf )
    src="${name}.tar.gz"
    dest="${name}-${fversion}.tar.gz"
    link="${purl}/$src"
    if [ ! -f ../roles/${name}/files/$dest ]
    then
      if [ "$name" == "eggroll" ]; then
        link="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/${name}/${fversion/-//}/$src" 
      fi
      if [ "$name" == "fateflow" ]; then
        curl ${purl}/examples.tar.gz -o ../roles/${name}/files/fate_examples-${fversion}.tar.gz
        curl ${purl}/fate.tar.gz -o ../roles/${name}/files/fate-${fversion}.tar.gz
        curl ${purl}/fate.env -o ../roles/${name}/files/fate.env
        curl ${purl}/RELEASE.md -o ../roles/${name}/files/RELEASE.md
      fi
      echo "$link  ../roles/${name}/files/$dest"
      curl  $link -o ../roles/${name}/files/$dest
    fi
  done
}

case $1 in
  "init")
    shift
    init $@

    ;;

  "do")
    get_pinfo && download

    ;;

  *)
    echo "Usage: $0 init|do"
    ;;

esac
