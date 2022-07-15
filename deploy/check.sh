

def_is_in() {

  local bname=$1
  eval local barray\=\( \${${bname}[*]} \)
  local key=$2

  echo ${key} | grep -Eq '[a-z]+:[0-9]+'
  if [ $? -eq 1 ]
  then
    #echo "check $module: unvid(format)"
    #return 1
 
    code=$( echo ${barray[*]} | grep -wq "${key%:*}" && echo 0 || echo 1 )
    if [ $code -eq 1 ]
    then
      echo "check $module: unvid(name)"
      return 1
    fi
  fi
  
}

def_check_role_ips() {

    local role=$1
    local temp=$2
    case ${temp%:*} in 
      "rollsite")
	if [ "$role" == "exchange" ]
	then
          echo "${temp#*:}" | grep -Eq '^[0-9]+.[0-9]+.[0-9]+.[0-9]+$|^[0-9.|]+$'
        else
          echo "${temp#*:}" | grep -Eq '^[0-9]+.[0-9]+.[0-9]+.[0-9]+$'
        fi
        if [ "$?" -eq 1 ]
        then
          echo "check ${role}_ips: \"$temp\" unvalid"
          return 1
        fi
      ;;
      "default"|"fateboard"|"clustermanager"|"fate_flow"|"mysql")
        echo "${temp#*:}" | grep -Eq '^[0-9]+.[0-9]+.[0-9]+.[0-9]+$'
        if [ "$?" -eq 1 ]
        then
          echo "check ${role}_ips: \"$temp\" unvalid"
          return 1
        fi
      ;;
      "nodemanager")
        for ip in $( echo "${temp#*:}" | tr -s '|' ' ' ) 
        do 
          echo "${ip}" | grep -Eq '^[0-9]+.[0-9]+.[0-9]+.[0-9]+$'
          if [ "$?" -eq 1 ]
          then
            echo "check ${role}_ips: \"$temp\" unvalid"
            return 1
          fi
        done
      ;;
      '*')
        echo "check ${role}_ips: \"$temp\" unvalid"
        return 1
      ;;
    esac
}

def_check_route() {

  local role=$1
  local temp=$2

  echo "${temp}" | grep -Eq '^[a-zA-Z0-9]+:([0-9]+.[0-9]+.[0-9]+.[0-9]+|[a-z0-9.-]+):[0-9]+?[a-z]?'
  if [ "$?" -eq 1 ]
  then
    echo "check ${role}_special route: \"$temp\" unvalid"
    return 1
  fi
}

def_check_main() {

  echo "-------------------0 check setup.conf--------------------------------"
  local deploy_modes=( "deploy" "install" "config" "uninstall" )
  local tdeploy_mode=$( ./bin/yq eval '.deploy_mode'  conf/setup.conf )
  echo ${deploy_modes[*]} | grep -wq "${tdeploy_mode}"
  if [ "$?" -eq 1 ]
  then
    echo "check deploy_mode: ${tdeploy_mode} unvalid"
    return
  fi
  echo "check deploy mode: valid"
 
  local bmodules=( "mysql" "eggroll" "fate_flow" "fateboard" )
  local modules=( $( ./bin/yq eval '.modules[]'  conf/setup.conf ) )
  for module in ${modules[*]};
  do
    def_is_in bmodules $module
    if [ "$?" -eq 1 ]
    then
      echo "check modules: $module unvalid"
      return
    fi
  done
  echo "check modules: valid"

  local broles=( "exchange" "host" "guest" )
  local roles=( $( ./bin/yq eval '.roles[]'  conf/setup.conf ) )
  for role in ${roles[*]};
  do
    def_is_in broles ${role} 
    if [ "$?" -eq 1 ]
    then
      echo "check roles: $role unvalid"
      return
    fi
    eval is_${role%:*}_in\=1
  done
  echo "check roles: valid"

  local ssl_roles=( $( ./bin/yq eval '.ssl_roles[]'  conf/setup.conf ) )
  for ssl_role in ${ssl_roles[*]};
  do
    def_is_in roles "${ssl_role}" 
    if [ "$?" -eq 1 ]
    then
      echo "check ssl_roles: ${ssl_role} unvalid"
      return
    fi
  done
  echo "check ssl_roles: valid"


  for trole in ${roles[*]};
  do
    #echo "check ${trole%:*} ips"
    eval local t_ips\=\( \"$( ./bin/yq eval '.'"${trole%:*}"'_ips[]'  conf/setup.conf )\"  \)

    echo ${t_ips[*]} | grep -qw "default" 
    if [ "$?" -ne 0 ]
    then
      if [ "${trole%:*}" != "exchange" ]
      then
        echo "check ${trole%:*}_ips: unvalid(no default setting)"
        return
      else	
        echo ${t_ips[*]} | grep -qw "rollsite" 
        if [ "$?" -ne 0 ]
        then
          echo "check ${trole%:*}_ips: unvalid(no rollsite or default setting)"
          return
        fi
      fi
    fi
    for temp in ${t_ips[*]};
    do
      def_check_role_ips ${trole%:*} $temp || return 
    done
    eval is_in\=\${is_${trole%:*}_in}
    if [ "${is_in}" -eq 1 -a "${#t_ips}" -eq 0 ]
    then
      echo "check ${trole%:*}_ips: unvalid(no ips)"
      return 
    fi
    echo "check ${trole%:*}_ips: valid"

    #echo "check ${trole%:*} special routes"
    eval local t_special_routes\=\( $( ./bin/yq eval '.'"${trole%:*}"'_special_routes[]'  conf/setup.conf ) \)
    for temp in ${t_special_routes[*]};
    do
      if [ "${trole%:*}" == "exchange" ]
      then
        def_check_route exchange $temp || return
      else
        def_check_route ${trole%:*} $temp || return
      fi
    done
    echo "check ${trole%:*} special route: valid"

  done
}

def_check_main


