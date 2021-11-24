#!/bin/bash


workdir=$(cd $(dirname $0); pwd)
cd ${workdir}
chmod a+x ./bin/*

case $1 in
  "init")
    shift
    pname=$1
    case $pname in
      "fate")
        if [ -f "build-fate.sh" ]; then
          /bin/bash build-fate.sh init $@
        else
          echo "to be supported"
        fi
      ;;

      "fate-serving")
        if [ -f "build-fate-serving.sh" ]; then
          /bin/bash build-fate-serving.sh init $@
        else
          echo "to be supported"
        fi
      ;;

      *)
        echo "Usage: $0 init [fate|fate-serving]"
      ;;
    esac

    ;;

  "do")
    pname=( $( ${workdir}/bin/yq eval '.project' ${workdir}/conf/setup.conf ) )
    case $pname in
      "fate")
        if [ -f "build-fate.sh" ]; then
          /bin/bash build-fate.sh $1
        else
          echo "to be supported"
        fi
      ;;

      "fate-serving")
        if [ -f "build-fate-serving.sh" ]; then
          /bin/bash build-fate-serving.sh $1
        else
          echo "to be supported"
        fi
      ;;

      *)
        echo "Usage: $0 $1"
      ;;
    esac

    ;;

  *)
    echo "Usage: $0 init|do"
    ;;

esac

