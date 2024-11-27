#!/bin/bash

workdir=$(cd $(dirname $0); pwd)
base="${workdir}/.."
cd ${workdir}
mkdir -p ${base}/logs
chmod a+x ./bin/*

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

/bin/bash deploy-fate.sh ${args[*]}
