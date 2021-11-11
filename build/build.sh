#!/bin/bash


workdir=$(cd $(dirname $0); pwd)
cd ${workdir}

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

      "fate-cloud")
        if [ -f "build-fate-cloud.sh" ]; then
          /bin/bash build-fate-cloud.sh init $@
        else
          echo "to be supported"
        fi
      ;;

      "fate-studio")
        if [ -f "build-fate-studio.sh" ]; then
          /bin/bash build-fate-studio.sh init $@
        else
          echo "to be supported"
        fi
      ;;

      *)
        echo "Usage: $0 init [fate|fate-serving|fate-cloud|fate-studio]"
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

      "fate-cloud")
        if [ -f "build-fate-cloud.sh" ]; then
          /bin/bash build-fate-cloud.sh $1 
        else
          echo "to be supported"
        fi
      ;;

      "fate-studio")
        if [ -f "build-fate-studio.sh" ]; then
          /bin/bash build-fate-studio.sh $1
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

