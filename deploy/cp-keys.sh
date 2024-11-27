#!/bin/bash

def_check_args() {
  local name=$1 
  local key=$2
  eval local temps\=\${$name[*]}
  echo ${temps[*]} | grep -qw $key 
  return $?
}

workdir=$(cd $(dirname $0); pwd)
cd $workdir
now=$( date +%s )

mkdir -p ${workdir}/../backups/${now}/keys/
kdir="${workdir}/../roles/eggroll/files/keys"
ls ${kdir}/* 1>/dev/null 2>&1 && mv ${kdir}/* ${workdir}/../backups/${now}/keys/ && echo "backups ${kdir}/*"
ssl_roles=( $1 $2 )

i=0
for role in host guest exchange;
do
  def_check_args ssl_roles $role
  if [ $? == 0 ]
  then
    i=$( expr $i + 1 )
  fi
done
[ $i != ${#ssl_roles[*]} ] && { echo "$0 host|guest|exchange host|guest|exchange"; exit 1; }

case ${#ssl_roles[*]} in
  2)
    
    aside=${ssl_roles[0]}
    bside=${ssl_roles[1]}
   
    for name in $aside $bside;
    do
      for kname in ca.pem server.key server.pem;
      do
        ddir="${workdir}/../roles/eggroll/files/keys/${name}"
        dfile="${ddir}/${name}-${kname}"
        [ ! -d $ddir ] && mkdir -p $ddir
        cp keys/${name}/${kname}  ${dfile} && echo "cp keys/${name}/${kname}  ${dfile} ok" || echo "cp keys/${name}/${kname}  ${dfile} failed"
      done
    done

    for kname in ca.pem client.pem client.key;
    do
      ddir="${workdir}/../roles/eggroll/files/keys/${bside}"
      dfile="${ddir}/${bside}-client-$kname"
      [ ! -d $ddir ] && mkdir -p $ddir
      cp keys/${aside}/${kname} $dfile && echo "cp keys/${aside}/${kname}  $dfile ok" || echo "cp keys/${aside}/${kname}  $dfile failed" 
    done

    for kname in ca.pem client.pem client.key;
    do
      ddir="${workdir}/../roles/eggroll/files/keys/${aside}"
      dfile="${ddir}/${aside}-client-$kname"
      [ ! -d $ddir ] && mkdir -p $ddir
      cp keys/${bside}/${kname} $dfile && echo "cp keys/${bside}/${kname}  $dfile ok" || echo "cp keys/${bside}/${kname}  $dfile failed" 
    done

  ;;

  1)
    role=${ssl_roles[0]}
    for kname in ca.pem server.key server.pem; do
      ddir="${workdir}/../roles/eggroll/files/keys/${role}"
      dfile="${ddir}/${role}-${kname}"
      [ ! -d $ddir ] && mkdir -p $ddir
      cp keys/${role}/${kname} ${dfile} && echo "cp keys/${role}/${kname}  $dfile ok" || echo "cp keys/${role}/${kname}  $dfile failed"
    done
    
    for kname in ca.pem client.pem client.key; do
      ddir="${workdir}/../roles/eggroll/files/keys/${role}"
      dfile="${ddir}/${role}-client-${kname}"
      [ ! -d $ddir ] && mkdir -p $ddir
      cp keys/${role}/${kname} ${dfile} && echo "cp keys/${role}/${kname}  $dfile ok" || echo "cp keys/${role}/${kname}  $dfile failed"
    done
  ;;

  *)
    echo "Usage: $0 role1 role2"
    ;;
esac >> ${workdir}/../logs/keys-${now}.log 2>&1 



