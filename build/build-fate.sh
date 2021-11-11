#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
cd $workdir

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
}


download() {
  url="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com"
  mysql="mysql-8.0.13.tar.gz"
  java="jdk-8u192.tar"
  python="fate_python-${product_fate_version%-*}.tar.gz"
  supervisor="fate_supervisor.tar.gz"  
  if [ ! -f ${workdir}/../roles/python/files/pip-packages-fate-${product_fate_version%-*}.tar.gz ]; then
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
  if [ ! -f ${workdir}/../roles/java/files/$java ]; then
    echo "-------------Download JDK package-----------"
    echo "wget -P ${workdir}/../roles/java/files/ ${url}/${java}"
    wget -P ${workdir}/../roles/java/files/ ${url}/${java}
  fi
  if [ ! -f ${workdir}/../roles/supervisor/files/supervisord-conf-1.1.4.tar.gz ]; then
    echo "-------------Download supervisor package-----------"
    echo "wget -P ${workdir}/../roles/supervisor/files/ ${url}/${supervisor}"
    wget -P ${workdir}/../roles/supervisor/files/ ${url}/${supervisor}
    tar xf  ${workdir}/../roles/supervisor/files/${supervisor} -C  ${workdir}/../roles/supervisor/files/
    rm ${workdir}/../roles/supervisor/files/${supervisor}
  fi

  echo "-------------Download $project package-----------"
  if [ "${product_fate_version%-*}" == "${product_fate_version#*-}" ]; then
    purl="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/$project/${product_fate_version}/release"
  else
    purl="https://webank-ai-1251170195.cos.ap-guangzhou.myqcloud.com/$project/${product_fate_version/-//}"
  fi
  if [ ! -f ../roles/check/files/deploy.tar.gz -o ! -f ../roles/check/files/build.tar.gz ]; then
    curl ${purl}/deploy.tar.gz -o ../roles/check/files/deploy.tar.gz
    curl ${purl}/build.tar.gz -o ../roles/check/files/build.tar.gz
  fi
  for name in $( ${workdir}/bin/yq eval '.product_fate_versions|keys|.[]' ${workdir}/conf/setup.conf); do
    fversion=$( ${workdir}/bin/yq eval '.product_fate_versions.'"$name"'' ${workdir}/conf/setup.conf )
    tp="${name}-build-${fversion}.tar.gz"
    link="${purl}/$tp"
    echo "$link  ../roles/${name}/files/${tp}"
    if [ ! -f ../roles/${name}/files/$temp ]
    then
      curl  $link -o ../roles/${name}/files/${tp}
      tar xf ../roles/${name}/files/${tp} -C ../roles/${name}/files/
      rm ../roles/${name}/files/${tp}
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
