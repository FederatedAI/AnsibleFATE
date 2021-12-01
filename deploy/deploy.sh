#!/bin/bash


workdir=$(cd $(dirname $0); pwd)
base="${workdir}/.."
cd ${workdir}
mkdir -p ${base}/logs
chmod a+x ./bin/*

pname=( $( ${workdir}/bin/yq eval '.project' ${base}/build/conf/setup.conf ) )

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

case $pname in 

  "fate")
    if [ -f "deploy-fate.sh" ]
    then
      /bin/bash deploy-fate.sh  ${args[*]}
    else
      echo "to be supported"
    fi
  ;;

  "fate-serving")
    if [ -f "deploy-fate-serving.sh" ]
    then
      /bin/bash deploy-fate-serving.sh  ${args[*]}
    else
      echo "to be supported"
    fi
  ;;

  *)
    echo "Error: not have deploy/deploy-${pname}.sh file"
  ;;

esac
