#!/bin/bash


def_check_setup() {
  local cnames=( "modules" "host_ips" "host_special_routes" "guest_ips" "guest_special_routes"  )
  for cname in ${cnames[*]};
  do
    tvar=( $( ${workdir}/bin/yq eval '.'"${cname}"'[]' ${workdir}/conf/setup.conf ) )
    ttvar="$( ${workdir}/bin/yq eval '.'"${cname}"'' ${workdir}/conf/setup.conf )"
    if [ "${tvar[*]}" == "" -a "$ttvar" != "[]" -a "$ttvar" != "" ]
    then
      echo "$cname:${tvar[*]}|${ttvar} unvaid"
      return 1
    fi
  done
}

def_get_base_data() {
  def_check_setup || exit 1

  pname=( $( ${workdir}/bin/yq eval '.pname' ${workdir}/conf/setup.conf ) )
  ssh_port=( $( ${workdir}/bin/yq eval '.ssh_port' ${workdir}/conf/setup.conf ) )
  base_roles=( $( ${workdir}/bin/yq eval '.roles[]' ${workdir}/conf/setup.conf ) )
  ssl_roles=( $( ${workdir}/bin/yq eval '.ssl_roles[]' ${workdir}/conf/setup.conf ) )
  deploy_user=( $( ${workdir}/bin/yq eval '.deploy_user' ${workdir}/conf/setup.conf ) )
  deploy_group=( $( ${workdir}/bin/yq eval '.deploy_group' ${workdir}/conf/setup.conf ) )

  roles=()
  for rinf in ${base_roles[*]};
  do
    roles=( ${rinf%:*} ${roles[*]} )
    eval ${rinf%:*}_pid\=${rinf#*:}
  done

  for role_name in ${roles[*]};
  do
    eval info_${role_name}_ips\=\( \"$( ${workdir}/bin/yq eval ".${role_name}_ips[]" ${workdir}/conf/setup.conf )\" \)
    eval info_${role_name}_special_routes\=\( $( ${workdir}/bin/yq eval ".${role_name}_special_routes[]" ${workdir}/conf/setup.conf ) \)
  done
  for role in ${roles[*]};
  do
    eval is_${role}_has_default_route\="false"
  done

  modules=( $( ${workdir}/bin/yq eval '.modules[]' ${workdir}/conf/setup.conf ) )
  if [ ${#modules[*]} == 0 ]
  then
    modules=( "mysql" "eggroll" "fate_flow" "fateboard" )
  fi
  deploy_mode=$( ${workdir}/bin/yq eval '.deploy_mode' ${workdir}/conf/setup.conf )
  deploy_env=$( ${workdir}/bin/yq eval '.env' ${workdir}/conf/setup.conf )

  polling_server_role=$( ./bin/yq e '.polling.server_role' ${workdir}/conf/setup.conf )
  polling_client_role=$( ./bin/yq e '.polling.client_role' ${workdir}/conf/setup.conf )
  if [ "${polling_server_role}" != "null" -a "${polling_client_role}" != "null" ]
  then
    eval polling_client_ids\=\( \${${polling_client_role}_pid} \)
  fi

  default_engines=$( ${workdir}/bin/yq eval '.default_engines' ${workdir}/conf/setup.conf )
  if [ "${default_engines}" == "spark" ]; then
    for role in "host" "guest"; do
      eval ${role}_compute_engine\=$( ${workdir}/bin/yq eval ".${role}_compute_engine" ${workdir}/conf/setup.conf )
      eval ${role}_spark_home\=$( ${workdir}/bin/yq eval ".${role}_spark_home" ${workdir}/conf/setup.conf )
      eval ${role}_hadoop_home\=$( ${workdir}/bin/yq eval ".${role}_hadoop_home" ${workdir}/conf/setup.conf )
      eval ${role}_storage_engine\=$( ${workdir}/bin/yq eval ".${role}_storage_engine" ${workdir}/conf/setup.conf )
      eval ${role}_hive_ips\=$( ${workdir}/bin/yq eval ".${role}_hive_ips" ${workdir}/conf/setup.conf )
      eval ${role}_hdfs_addr\=$( ${workdir}/bin/yq eval ".${role}_hdfs_addr" ${workdir}/conf/setup.conf )
      eval ${role}_mq_engine\=$( ${workdir}/bin/yq eval ".${role}_mq_engine" ${workdir}/conf/setup.conf )
      eval ${role}_rabbitmq_ips\=$( ${workdir}/bin/yq eval ".${role}_rabbitmq_ips" ${workdir}/conf/setup.conf )
      eval ${role}_pulsar_ips\=$( ${workdir}/bin/yq eval ".${role}_pulsar_ips" ${workdir}/conf/setup.conf )
      eval ${role}_nginx_ips\=$( ${workdir}/bin/yq eval ".${role}_nginx_ips" ${workdir}/conf/setup.conf )
    done
  fi

}

def_get_role_ips() {
  local role=$1
  eval ${role}_ips\=\(\)
  eval local tinfo_ips\=\( \${info_${role}_ips[*]} \)
  for temp in ${tinfo_ips[*]};
  do
    local role_module=${temp%:*}
    if [ "${role_module}" == "rollsite" -o "${role_module}" == "nodemanager" ]
    then
      temps=( $( echo ${temp#*:} | tr -s '|' ' ' ) )
      eval ${role}_${role_module}_ips\=\( ${temps[*]} \)
    else
      eval ${role}_${role_module}_ips\=\( ${temp#*:} \)
    fi
  done
  eval local tips\=\( \${${role}_default_ips[*]} \)
  if [ ${#tips[*]} == 0 ]
  then
    eval ${role}_default_ips\=\( \${${role}_rollsite_ips[0]} \)
  fi

  local role_modules=( "rollsite" "clustermanager" "nodemanager" "fate_flow" "fateboard" "mysql" )
  for role_module in ${role_modules[*]}
  do
    if [ "$role" == "host" -o "$role" == "guest" ]
    then
      eval local tips\=\( \${${role}_${role_module}_ips[*]} \)
      if [ "${#tips[*]}" == 0 ]
      then
        eval ${role}_${role_module}_ips\=\( \${${role}_default_ips[0]} \)
      fi
    else
      if [ "${role_module}" == "rollsite" -a "$role" == "exchange" ]
      then
        eval local tips\=\( \${${role}_rollsite_ips[*]} \)
        if [ "${#tips[*]}" == 0 ]
        then
          exchange_rollsite_ips=( ${exchange_default_ips[*]} )
        fi
      fi
    fi
  done
}


def_package_route() {
  rname=$1
  is_ssl_role=$2

  eval temps\=\( \${${rname}[*]} \)
  local party_ids=()
  for temp in ${temps[*]};
  do
    party_id="${temp%%:*}"
    eval local list_${party_id}\=\( $temp \${list_${party_id}} \)
    code=$( echo "${party_ids[@]}" | grep -wq "${party_id}" &&  echo 0 || echo 1 )
    if [ $code -eq 1 ]
    then
      party_ids=( ${party_ids[*]} ${temp%%:*} )
    fi
  done
  i=1
  n=${#party_ids[*]}
  if [ $n -gt 0 ]
  then
    local role_routes="["
  else
    local role_routes=""
  fi
  for party_id in  ${party_ids[*]};
  do
    eval tlists\=\( \${list_${party_id}[*]} \)
    nn=${#tlists[*]}
    ii=1
    local routes="["
    for tlist in ${tlists[*]};
    do
      local tmp=( $( echo ${tlist#*:} |tr -s ':' ' ') )
      local ip=${tmp[0]}
      local port=${tmp[1]}
      local is_secure=${tmp[2]}
      local name="default"
      if [ $port == 9360 -o $port == 9380 ]
      then
        name="fate_flow"
      fi
      if [ $ii == $nn ]
      then
        if [ "$name" == "fate_flow" ]
        then
          routes="${routes}{\"name\":\"fateflow\",\"ip\":\"$ip\",\"port\":$port}]"
        else
          if [ "${is_ssl_role:-false}" == "true" ]
          then
            port=9371
          fi
          if [ "${is_ssl_role:-false}" == "false" -a "${is_secure}" == "true" ]; then
            port=${tmp[1]}
            routes="${routes}{\"name\":\"${name}\",\"ip\":\"$ip\",\"port\":$port,\"is_secure\":${is_secure:-false}}]"
            continue
          fi
          routes="${routes}{\"name\":\"${name}\",\"ip\":\"$ip\",\"port\":$port,\"is_secure\":${is_ssl_role:-false}}]"
        fi
      else
        if [ "$name" == "fate_flow" ]
        then
          routes="${routes}{\"name\":\"fateflow\",\"ip\":\"$ip\",\"port\":$port},"
        else
          if [ "${is_ssl_role:-false}" == "true" ]
          then
            port=9371
          fi
          if [ "${is_ssl_role:-false}" == "false" -a "${is_secure}" == "true" ]; then
            port=${tmp[1]}
            routes="${routes}{\"name\":\"${name}\",\"ip\":\"$ip\",\"port\":$port,\"is_secure\":${is_secure:-false}}]"
            continue
          fi
          routes="${routes}{\"name\":\"${name}\",\"ip\":\"$ip\",\"port\":${port},\"is_secure\":${is_ssl_role:-false}},"
        fi
      fi
      ii=$( expr $ii + 1 )
    done
    if [ $i == $n ]
    then
      role_routes="${role_routes}{\"id\":${party_id},\"routes\":$routes}]"
    else
      role_routes="${role_routes}{\"id\":${party_id},\"routes\":$routes},"
    fi
    i=$( expr $i + 1 )
  done
  if [ -z "${role_routes}" ]
  then
    echo "[]"
  else
    echo "${role_routes}"
  fi
}

def_get_info_role_default_route() {
  role=$1
  party_id=$2
  eval local info_${role}_default_routes\=\(\)
  eval local role_ips=( \${${role}_rollsite_ips[*]} )
  for ip in ${role_ips[*]};
  do
    eval info_${role}_default_routes\=\( \${info_${role}_default_routes[*]} "${party_id}:${ip}:9370" \)
  done
  code=$( echo ${ssl_roles[*]} | grep -wq "$role" && echo 0 || echo 1 )
  if [ "$code" == 0 ]
  then
    is_ssl_role="true"
    local tdroute=$(def_package_route "info_${role}_default_routes" ${is_ssl_role} )
  else
    local tdroute=$(def_package_route "info_${role}_default_routes")
  fi
  echo $tdroute
}

def_get_default_route() {
  role=$1
  case ${#roles[*]} in
    3)
      if [ "$role" == "exchange" ]
      then
        local tdroute1=( $(def_get_info_role_default_route host ${host_pid}) )
        local tdroute2=( $(def_get_info_role_default_route guest ${guest_pid}) )
        echo "${tdroute1%]*},${tdroute2#*[}"
      else
        eval local has_default_route\=\${is_${role}_has_default_route}
        if [ "${has_default_route}" == "false" ]
        then
          local tdroute=( $(def_get_info_role_default_route exchange "default") )
          local code=$( echo ${ssl_roles[*]} | grep -wq "$role" && echo 0 || echo 1 )
          if [ $code -eq 0 ]
          then
            echo "${tdroute}"
          else
            echo "${tdroute}"|sed 's#true#false#g;s#9371#9370#g'
          fi
        else
          echo "[]"
        fi
      fi
    ;;

    2)
      #echo "party number: 2"
      code=$( echo ${roles[*]} | grep -wq "exchange" &&  echo 0 || echo 1 )
      if [ $code -eq 0 ]
      then
        if [ "${role}" == "exchange" ]
        then
          code=$( echo ${roles[*]} | grep -wq "host" &&  echo 0 || echo 1 )
          if [ $code -eq 0 ]
          then
            local tdroute=( $(def_get_info_role_default_route host ${host_pid}) )
            echo "${tdroute}"
          else
            code=$( echo ${roles[*]} | grep -wq "guest" &&  echo 0 || echo 1 )
            if [ $code -eq 0 ]
            then
              local tdroute=( $(def_get_info_role_default_route guest ${guest_pid} ) )
              echo "${tdroute}"
            else
              echo "[]"
            fi
          fi
        else
          code=$( echo ${roles[*]} | grep -wq "$role" &&  echo 0 || echo 1 )
          if [ $code -eq 0 ]
          then
            eval local has_default_route\=\${is_${role}_has_default_route}
            if [ "${has_default_route}" == "false" ]
            then
              local tdroute=( $(def_get_info_role_default_route exchange default ) )
              echo "${tdroute}"
            else
              echo "[]"
            fi
          fi
        fi
      else
        code=$( echo ${roles[*]} | grep -wq "$role" &&  echo 0 || echo 1 )
        if [ $code -eq 0 ]
        then
          if [ $role == "host" ]
          then
            eval local has_default_route\=\${is_${role}_has_default_route}
            if [ "${has_default_route}" == "false" ]
            then
              local tdroute=( $(def_get_info_role_default_route guest default ) )
              echo "${tdroute}"
            else
              echo "[]"
            fi
          else
            if [ $role == "guest" ]
            then
              eval local has_default_route\=\${is_${role}_has_default_route}
              if [ "${has_default_route}" == "false" ]
              then
                local tdroute=( $(def_get_info_role_default_route host default ) )
                echo "${tdroute}"
              else
                echo "[]"
              fi
            fi
          fi
        fi
      fi

    ;;

    1)
      echo ""

    ;;

    *)
      echo "roles data wrong"
    ;;

esac
}

def_format_special_routes() {
  local role=$1

  i=1
  eval j=\${#info_${role}_special_routes[*]}
  eval tinfo_special_routes\=\${info_${role}_special_routes[*]};
  eval temp_${role}_special_routes\=\(\)
  for temp in ${tinfo_special_routes[*]};
  do
    local is_secure=false
    party_id=${temp%%:*}
    if [ "${party_id}" == "default" ]
    then
      eval is_${role}_has_default_route\="true"
      #echo "set is_${role}_has_default_route true"
    fi
    tips=( $( echo ${temp#*:} |tr -s ':' ' ') )
    ip=${tips[0]}
    port=9370
    if [ ${#tips[*]} == 2 ]; then
      port=${tips[1]}
    elif [ ${#tips[*]} == 3 -a "${tips[2]}" == "secure" ]; then
      port=${tips[1]}
      local is_secure=true
    fi
    if [ "${is_secure}" == "true" ]; then
      eval temp_${role}_special_routes\=\( \${temp_${role}_special_routes[*]} "${party_id}:${ip}:${port}:${is_secure}" \)
    else
      eval temp_${role}_special_routes\=\( \${temp_${role}_special_routes[*]} "${party_id}:${ip}:${port}" \)
    fi
    i=$( expr $i + 1 )
  done
}

def_format_role_self_routes() {
  echo "def_format_role_self_routes"

  local role=$1
  eval local tfate_flow_ips=( \${${role}_fate_flow_ips[*]} )

  local len=${#tfate_flow_ips[*]}
  if [ $len == 0 ]
  then
    eval ${role}_fate_flow_ips\=\( \${${role}_rollsite_ips[*]} \)
  fi

  local self_routes=""
  role_modules=( "rollsite" "fate_flow" )
  local i=1
  for role_module in ${role_modules[*]}
  do
    eval local party_id=\${${role}_pid}
    eval local tips\=\${${role}_${role_module}_ips[*]}
    eval ${role}_${role_module}_routes\=\(\)
    for ip in ${tips[*]}
    do
      if [ "${role_module}" == "rollsite" ]
      then
        local port=9370
      else
        local port=9360
      fi
      eval ${role}_${role_module}_routes\=\( \${${role}_${role_module}_routes[*]}  "${party_id}:${ip}:${port}" \)
    done
    eval local name="${role}_${role_module}_routes"

    local is_ssl_role="false"
    local tdroute=$( def_package_route "${name}" "${is_ssl_role}" )
    if [ $i == 1 ]
    then
      self_routes="${tdroute}"
    else
      local t1=$( echo ${self_routes}|sed 's#\(.*\)\]\}\]#\1#'|tr -s '"' '\"' |tr -s '[' '\[' | tr -s ']' '\]'|tr -s '{' '\{' | tr -s '}' '\}' )
      local t2=$( echo ${tdroute} | sed 's#.*routes\"\:\[\(.*\)#\1#' | tr -s '"' '\"' |tr -s '[' '\[' | tr -s ']' '\]' |tr -s '{' '\{' | tr -s '}' '\}' )
      self_routes="$t1,$t2"
    fi
    i=$( expr $i + 1 )
  done
  eval ${role}_self_routes\=\'$( echo ${self_routes} | tr -s '"' '\"' |tr -s '[' '\[' | tr -s ']' '\]' |tr -s '{' '\{' | tr -s '}' '\}' )\'
  eval echo "${role}_self_routes: \${${role}_self_routes}"
}


def_render_hosts() {
  dfile=$1

  echo "def_render_hosts"
  tpl="tpl/hosts.tpl"
  all_variables="pname=${pname} ssh_port=${ssh_port} user=${deploy_user}"
  content=$( cat $tpl )
  printf "${all_variables}\ncat <<EOF\n${content}\nEOF" | bash > $dfile

  all_ips=()
  for role in ${roles[*]};
  do
    for module in ${modules[*]};
    do
      if [ "$module" == "eggroll" ]
      then
        for role_module in rollsite nodemanager clustermanager;
        do
          eval tips\=\(\${${role}_${role_module}_ips[*]}\)
          for tip in ${tips[*]};
          do
            code=$( echo ${all_ips[*]} | grep -wq $tip && echo 0 || echo 1 )
            if [ $code -eq 1 ]
            then
              all_ips=( ${all_ips[*]} $tip )
            fi
          done
        done
      else
        eval tips\=\(\${${role}_${module}_ips[*]}\)
        for tip in ${tips[*]};
        do
          code=$( echo ${all_ips[*]} | grep -wq $tip && echo 0 || echo 1 )
          if [ $code -eq 1 ]
          then
            all_ips=( ${all_ips[*]} $tip )
          fi
        done
      fi
    done
  done
  echo "all_ips: ${all_ips[*]}"

  for tip in ${all_ips[*]};
  do
    sed -i '$i '"$tip"'\n' $dfile
  done
  sed -i '/^$/d' $dfile
}
def_render_base_init() {
  echo "def_render_base_init"
  dfile=$1
  myvars="deploy_user=${deploy_user} deploy_group=${deploy_group}"
  eval eval  ${myvars} "${workdir}/bin/yq  e  \' "\
          " .supervisord.service.owner \=env\(deploy_user\) \| "\
          " .supervisord.service.group \=env\(deploy_group\)  "\
          " \' ${workdir}/files/base_init -I 2 -P " > $dfile
}

def_render_fate_init() {
  echo "def_render_fate_init"

  dfile=$1
  local deploy_roles="[$( echo ${roles[*]} | tr -s ' ' ',' )]"
  local deploy_modules="[$( echo ${modules[*]} | tr -s ' ' ',' )]"
  local ssl_roles="[$( echo ${ssl_roles[*]} | tr -s ' ' ',' )]"

  myvars="deploy_mode=${deploy_mode} deploy_modules=${deploy_modules} roles=${deploy_roles} ssl_roles=${ssl_roles} default_engines=${default_engines}"
  eval eval  ${myvars} "${workdir}/bin/yq  e  \' "\
          " .deploy_mode \|\=env\(deploy_mode\) \| "\
          " .deploy_modules \|\=env\(deploy_modules\) \| "\
          " .deploy_roles \|\=env\(roles\) \| "\
          " .ssl_roles \|\=env\(ssl_roles\) \| "\
          " .default_engines\|\=env\(default_engines\)  "\
          " \' ${workdir}/files/fate_init -I 2 -P " > $dfile
}

def_render_playbook() {
  echo "def_render_playbook"

  dfile="$1"
  case "${deploy_mode}" in

    "install"|"uninstall"|"deploy"|"config")
      if [ "${deploy_mode}" == "uninstall" ]; then
        if [ "${default_engines}" != "spark" ]; then
          cp ${workdir}/files/project-uninstall.yaml $dfile
        else
          cp ${workdir}/files/spark-project-uninstall.yaml $dfile
        fi
      else
        if [ "${default_engines}" != "spark" ]; then
          cp ${workdir}/files/project-install.yaml $dfile
        else
          cp ${workdir}/files/spark-project-install.yaml $dfile
        fi
      fi
      sed -i 's#ENV#'"${deploy_env}"'#g;s#PNAME#'"${pname}"'#g' $dfile
      for role in "host" "guest" "exchange";
      do
        code=$( echo ${roles[*]} | grep -wq "$role" && echo 0 || echo 1 )
        if [ $code -eq 1 ]
        then
          sed -i '/var_files\/'"${deploy_env}"'\/'"${pname}"'_'"$role"'/d' $dfile
        fi
      done

      local i=0
      [ "${default_engines}" != "spark" ] && all_modules=( "mysql" "eggroll" "fateflow" "fateboard" ) || all_modules=( "mysql" "fateflow" "fateboard" )
      if [ "${deploy_mode}" == "uninstall" ]; then
        [ "${default_engines}" != "spark" ] && all_modules=( "mysql_uninstall" "eggroll_uninstall" "fateflow_uninstall" "fateboard_uninstall" ) || all_modules=( "mysql_uninstall" "fateflow_uninstall" "fateboard_uninstall" )
      fi

      tmodules=()
      for module in ${modules[*]};
      do
        if [ "$module" == "fate_flow" ]
        then
          tmodules=( "fateflow" ${tmodules[*]} )
        else
          tmodules=( "$module" ${tmodules[*]} )
       fi
      done
      for tmodule in ${all_modules[*]};
      do
        code=$( echo ${tmodules[*]} | grep -wq "${tmodule%_*}" && echo 0 || echo 1 )
        if [ $code -eq 1 ]
        then
          if [ "${tmodule%_*}" == "eggroll" -o "${tmodule%_*}" == "fateflow" ]
          then
            i=$( expr $i + 1 )
          fi
          sed -i '/role: "'"${tmodule}"'"/d' $dfile
        fi
      done
      if [ ${deploy_mode} != "uninstall" ]; then
        if [ $i -eq 2 -o "${deploy_mode}" != "deploy" ]
        then
          sed -i '/role: "python",/d' $dfile
          sed -i '/role: "rabbitmq",/d' $dfile
        fi
        if [ "${default_engines}" == "spark" -a $i -eq 1 ]; then
          sed -i '/role: "python",/d' $dfile
          sed -i '/role: "rabbitmq",/d' $dfile
        fi
      fi
    ;;

    *)
      echo "Usage: $0 install|uninstall"
    ;;

  esac
}

def_render_setup() {
  mkdir -p ${workdir}/conf

  local deploy_host_ips="[$( echo ${host_ips[*]} | tr -s ' ' ',' )]"
  local deploy_guest_ips="[$( echo ${guest_ips[*]} | tr -s ' ' ',' )]"
  if [ ${#exchange_ips[*]} -gt 1 ]
  then
    local deploy_exchange_ips="[$( echo ${exchange_ips[*]} | tr -s ' ' ',' )]"
  else
    local deploy_exchange_ips="[\"$( echo ${exchange_ips[*]} | tr -s ' ' ',' )\"]"
  fi
  local deploy_roles="[$( echo ${roles[*]} | tr -s ' ' ',' )]"
  local deploy_ssl_roles="[$( echo ${ssl_roles[*]} | tr -s ' ' ',' )]"
  myvars="deploy_mode\=\${deploy_mode}  \
        host_ips\=${deploy_host_ips} \
        guest_ips\=${deploy_guest_ips} \
        exchange_ips\=${deploy_exchange_ips/|/\|} \
        ssl_roles\=${deploy_ssl_roles} \
        roles\=${deploy_roles} \
        default_engines\=${engines}"

  if [ -n "${engines}" -a "${engines}" == "spark" ]; then
    if [ ${#exchange_ips[*]} -ge 1 ]; then
      echo "error: spark no exchange"
      exit 1
    fi
    if [ ${#ssl_roles[*]} -gt 0 ]; then
      echo "error: Spark does not support ssl mode"
      exit 1
    fi
    eval eval  ${myvars} "${workdir}/bin/yq  e  \' "\
            " .deploy_mode \|\=env\(deploy_mode\) \| "\
            " .roles \|\=env\(roles\) \| "\
            " .host_ips \|\=env\(host_ips\) \| "\
            " .guest_ips \|\=env\(guest_ips\) \| "\
            " .default_engines \|\=env\(default_engines\) "\
            " \' ${workdir}/files/spark_setup.conf -I 2 -P " > ${workdir}/conf/setup.conf
  else
    eval eval  ${myvars} "${workdir}/bin/yq  e  \' "\
            " .deploy_mode \|\=env\(deploy_mode\) \| "\
            " .roles \|\=env\(roles\) \| "\
            " .ssl_roles \|\=env\(ssl_roles\) \| "\
            " .host_ips \|\=env\(host_ips\) \| "\
            " .guest_ips \|\=env\(guest_ips\) \| "\
            " .exchange_ips \|\=env\(exchange_ips\) \| "\
            " .default_engines \|\=env\(default_engines\)  "\
            " \' ${workdir}/files/setup.conf -I 2 -P " > ${workdir}/conf/setup.conf
  fi
}

def_render_roles_core() {
  local role=$1
  local pname=$2
  local base=$3

  code=$( echo ${ssl_roles[*]} | grep -wq "$role" && echo 0 || echo 1 )
  if [ $code == 0 ]
  then
    local server_secure=true
    local client_secure=true
  else
    local server_secure=false
    local client_secure=false
  fi

  case $role in
    "host"|"guest")
      myvars=""
      local role_enable="true"
      eval local trole_ips=( \${${role}_ips[*]} )
      local role_modules=( "rollsite" "clustermanager" "nodemanager" "fate_flow" "fateboard" "mysql" )
      for role_module in ${role_modules[*]};
      do
        eval local i=\${#${role}_${role_module}_ips[*]}
        eval local tips=\${${role}_${role_module}_ips[*]}
        if [ $i -gt 1 ]
        then
          local tt_ips=$( echo ${tips[*]} | tr -s ' ' ',' )
          eval local ${role_module}_ips\="[${tt_ips}]"
        else
          eval local ${role_module}_ips\="[$( echo \${${role}_${role_module}_ips[*]} | tr -s ' ' ',' )]"
        fi
        if [ "${role_module}" == "rollsite" -o "${role_module}" == "clustermanager" -o "${role_module}" == "nodemanager" ]
        then
          code=$( echo ${modules[*]} | grep -wq "eggroll" && echo 0 || echo 1 )
        else
          code=$( echo ${modules[*]} | grep -wq "${role_module}" && echo 0 || echo 1 )
        fi
        if [ "$code" == 0 ]
        then
          eval local ${role_module}_enable=true
        else
          eval local ${role_module}_enable=false
        fi
      done

      eval local special_routes=\'$( echo \${${role}_special_routes} | tr -s '"' '\"' | tr -s '[' '\[' | tr -s ']' '\]')\'
      eval local default_routes=\'$( echo \${${role}_default_routes} | tr -s '"' '\"' | tr -s '[' '\[' | tr -s ']' '\]')\'
      eval local self_routes=\'$( echo \${${role}_self_routes} | tr -s '"' '\"' | tr -s '[' '\[' | tr -s ']' '\]')\'

      if [ "$role" == "${polling_client_role}" ]
      then
        polling_enable=true
      else
        polling_enable=false
      fi

      #echo "========================================================"
      #eval echo "special_routes: ${special_routes}"
      #eval echo "default_routes: ${default_routes}"
      #eval echo "self_routes: ${self_routes}"
      #echo "========================================================"

      eval len_default_routes\=\${#${role}_default_routes}
      eval len_special_routes\=\${#${role}_special_routes}

      if [ ${len_default_routes} -eq 0 ]
      then
        default_routes='[]'
      fi
      if [ ${len_special_routes} -eq 0 ]
      then
        special_routes='[]'
      fi

      if [ "${default_engines}" == "spark" ]; then
        eval local pid=\${${role}_pid}
        eval local compute_engine="\${${role}_compute_engine}"
        eval local mq_engine="\${${role}_mq_engine}"
        eval local storage_engine="\${${role}_storage_engine}"
        eval local rabbitmq_ips="\${${role}_rabbitmq_ips}"
        eval local pulsar_ips="\${${role}_pulsar_ips}"
        eval local spark_home="\${${role}_spark_home}"
        eval local hadoop_home="\${${role}_hadoop_home}"
        eval local hive_ips="\${${role}_hive_ips}"
        eval local hdfs_addr="\${${role}_hdfs_addr}"
        eval local nginx_ips="\${${role}_nginx_ips}"
        for mq in "rabbitmq" "pulsar"; do
          if [ "${mq_engine}" == "$mq" ]; then
            eval local ${mq}_enable=true
          else
            eval local ${mq}_enable=false
          fi
        done
        for storage in "hive" "hdfs" "localfs"; do
          if [ "${storage_engine}" == "${storage}" ]; then
            eval local ${storage}_enable=true
          else
            eval local ${storage}_enable=false
          fi
        done
        [ "${compute_engine}" == "spark" ] && local spark_enable=true
        [ -n "${nginx_ips}" ] && local nginx_enable=true || local nginx_enable=false
        if [ ${#base_roles[*]} -eq 1 ]; then
          [ "x" != "x${rabbitmq_ips}" ] && local ${role}_rabbitmq_route\="[{\"id\":${pid},\"routes\":[{\"ip\":\"${rabbitmq_ips}\",\"port\":5672}]}]" || local ${role}_rabbitmq_route\="[]"
          [ "x" != "x${pulsar_ips}" ] && local ${role}_pulsar_route\="[{\"id\":${pid},\"routes\":[{\"ip\":\"${pulsar_ips}\",\"port\":6650,\"sslPort\":6651,\"proxy\":\"\"}]}]" || local ${role}_pulsar_route\="[]"
        else
          [ "x" != "x${rabbitmq_ips}" ] && local ${role}_rabbitmq_route\="[{\"id\":${host_pid},\"routes\":[{\"ip\":\"${host_rabbitmq_ips}\",\"port\":5672}]},{\"id\":${guest_pid},\"routes\":[{\"ip\":\"${guest_rabbitmq_ips}\",\"port\":5672}]}]" || local ${role}_rabbitmq_route\="[]"
          [ "x" != "x${pulsar_ips}" ] && local ${role}_pulsar_route\="[{\"id\":${host_pid},\"routes\":[{\"ip\":\"${host_pulsar_ips}\",\"port\":6650,\"sslPort\":6651,\"proxy\":\"\"}]},{\"id\":${guest_pid},\"routes\":[{\"ip\":\"${guest_pulsar_ips}\",\"port\":6650,\"sslPort\":6651,\"proxy\":\"\"}]}]" || local ${role}_pulsar_route\="[]"
        fi
        eval local rabbitmq_routes=\'$( echo \${${role}_rabbitmq_route} | tr -s '"' '\"' | tr -s '[' '\[' | tr -s ']' '\]' )\'
        eval local pulsar_routes=\'$( echo \${${role}_pulsar_route} | tr -s '"' '\"' | tr -s '[' '\[' | tr -s ']' '\]' )\'
        eval echo "${role}_rabbitmq_route: \${${role}_rabbitmq_route}"
        eval echo "${role}_pulsar_route: \${${role}_pulsar_route}"
        myvars="${myvars} \
              pid\=${pid}  \
              mysql_enable\=\${mysql_enable}  \
              mysql_ips\=${mysql_ips} \
              fateboard_enable\=\${fateboard_enable}  \
              fateboard_ips\=${fateboard_ips} \
              fate_flow_enable\=\${fate_flow_enable}  \
              fate_flow_ips\=${fate_flow_ips}  \
              mq_engine\=${mq_engine} \
              storage_engine\=${storage_engine} \
              spark_enable\=${spark_enable} \
              hadoop_home\=${hadoop_home} \
              hive_enable\=${hive_enable} \
              hdfs_enable\=${hdfs_enable} \
              nginx_enable\=${nginx_enable} \
              rabbitmq_enable\=${rabbitmq_enable} \
              pulsar_enable\=${pulsar_enable} \
              rabbitmq_ips\=${rabbitmq_ips:-127.0.0.1} \
              pulsar_ips\=${pulsar_ips:-127.0.0.1} \
              hive_ips\=${hive_ips:-127.0.0.1} \
              hdfs_addr\=${hdfs_addr} \
              nginx_ips\=${nginx_ips:-127.0.0.1} \
              rabbitmq_routes\=\${rabbitmq_routes} \
              pulsar_routes\=\${pulsar_routes} \
              spark_home\=${spark_home} "
        eval eval  ${myvars} "${workdir}/bin/yq  e  \' "\
              " .${role}.partyid\=env\(pid\) \| "\
              " .${role}.mysql.enable\=env\(mysql_enable\) \| "\
              " .${role}.mysql.ips\|\=env\(mysql_ips\) \| "\
              " .${role}.fateboard.enable\=env\(fateboard_enable\) \| "\
              " .${role}.fateboard.ips\|\=env\(fateboard_ips\) \| "\
              " .${role}.fate_flow.enable\=env\(fate_flow_enable\) \| "\
              " .${role}.fate_flow.ips\|\=env\(fate_flow_ips\) \| "\
              " .${role}.fate_flow.federation\|\=env\(mq_engine\) \|" \
              " .${role}.fate_flow.storage\|\=env\(storage_engine\) \|" \
              " .${role}.spark.enable\|\=env\(spark_enable\) \|" \
              " .${role}.spark.hadoop_home\|\=strenv\(hadoop_home\) \|" \
              " .${role}.hive.enable\|\=env\(hive_enable\) \|" \
              " .${role}.hdfs.enable\|\=env\(hdfs_enable\) \|" \
              " .${role}.nginx.enable\|\=env\(nginx_enable\) \|" \
              " .${role}.rabbitmq.enable\|\=env\(rabbitmq_enable\) \|" \
              " .${role}.pulsar.enable\|\=env\(pulsar_enable\) \|" \
              " .${role}.rabbitmq.host\|\=env\(rabbitmq_ips\) \|" \
              " .${role}.pulsar.host\|\=env\(pulsar_ips\) \|" \
              " .${role}.hive.host\|\=env\(hive_ips\) \|" \
              " .${role}.hdfs.name_node\|\=strenv\(hdfs_addr\) \|" \
              " .${role}.nginx.host\|\=env\(nginx_ips\) \|" \
              " .${role}.rabbitmq.route_table\|\=env\(rabbitmq_routes\) \|" \
              " .${role}.pulsar.route_table\|\=env\(pulsar_routes\) \|" \
              " .${role}.spark.home\|\=strenv\(spark_home\) " \
           " \' ${workdir}/files/fate_spark_${role} -I 2 -P " > ${base}/${pname:-fate}_${role}
      else
        myvars="${myvars} \
              mysql_enable\=\${mysql_enable}  \
              mysql_ips\=${mysql_ips} \
              fateboard_enable\=\${fateboard_enable}  \
              fateboard_ips\=${fateboard_ips} \
              fate_flow_enable\=\${fate_flow_enable}  \
              fate_flow_ips\=${fate_flow_ips}  \
              clustermanager_enable\=\${clustermanager_enable}  \
              clustermanager_ips\=${clustermanager_ips}  \
              nodemanager_enable\=\${nodemanager_enable}  \
              nodemanager_ips\=${nodemanager_ips}  \
              polling_enable\=\${polling_enable} \
              rollsite_enable\=\${rollsite_enable} \
              server_secure\=${server_secure} \
              client_secure\=${client_secure} \
              special_routes\=\${special_routes} \
              default_routes\=\${default_routes}  \
              self_routes\=\${self_routes}  \
              pid\=\${${role}_pid} \
              rollsite_ips\=${rollsite_ips} "
        eval eval  ${myvars} "${workdir}/bin/yq  e  \' "\
              " .${role}.rollsite.server_secure\|\=env\(server_secure\) \| "\
              " .${role}.rollsite.client_secure\|\=env\(client_secure\) \| "\
              " .${role}.mysql.enable\=env\(mysql_enable\) \| "\
              " .${role}.mysql.ips\|\=env\(mysql_ips\) \| "\
              " .${role}.fateboard.enable\=env\(fateboard_enable\) \| "\
              " .${role}.fateboard.ips\|\=env\(fateboard_ips\) \| "\
              " .${role}.fate_flow.enable\=env\(fate_flow_enable\) \| "\
              " .${role}.fate_flow.ips\|\=env\(fate_flow_ips\) \| "\
              " .${role}.nodemanager.enable\=env\(nodemanager_enable\) \| "\
              " .${role}.nodemanager.ips\|\=env\(nodemanager_ips\) \| "\
              " .${role}.clustermanager.enable\=env\(clustermanager_enable\) \| "\
              " .${role}.clustermanager.ips\|\=env\(clustermanager_ips\) \| "\
              " .${role}.rollsite.polling.enable\=env\(polling_enable\) \| "\
              " .${role}.rollsite.enable\=env\(rollsite_enable\) \| "\
              " .${role}.rollsite.route_tables\|\=env\(special_routes\) \| "\
              " .${role}.rollsite.route_tables \+\=env\(default_routes\) \| "\
              " .${role}.rollsite.route_tables \+\=env\(self_routes\) \| "\
              " .${role}.partyid\|\=env\(pid\) \| " \
              " .${role}.rollsite.ips\|\=env\(rollsite_ips\) " \
           " \' ${workdir}/files/fate_${role} -I 2 -P " > ${base}/${pname:-fate}_${role}
      fi

  ;;

  "exchange")
    local len_polling_client_ids=${#polling_client_ids}
    if [ ${len_polling_client_ids} -eq 0 ]
    then
      polling_enable=false
      polling_ids='[]'
    else
      polling_enable=true
      polling_ids="[${polling_client_ids[*]}]"

    fi
    if [ "$exchange_special_routes" == "" ]
    then
      exchange_special_routes='[]'
    fi
    if [  "$exchange_default_routes" == "" ]
    then
      exchange_default_routes='[]'
    fi
    rollsite_enable=true \
    server_secure=${server_secure} \
    client_secure=${client_secure} \
    rollsite_polling_enable=${polling_enable} \
    rollsite_polling_ids=${polling_ids} \
    special_route_tables=${exchange_special_routes} \
    default_route_tables="${exchange_default_routes}" \
    rollsite_ips="[$(echo ${exchange_rollsite_ips[*]}|tr -s ' ' ',')]"  ${workdir}/bin/yq  e '
      .exchange.rollsite.client_secure|=env(client_secure) |
      .exchange.rollsite.server_secure|=env(server_secure) |
      .exchange.rollsite.route_tables |=env(special_route_tables) |
      .exchange.rollsite.route_tables +=env(default_route_tables) |
      .exchange.rollsite.polling.enable|=env(rollsite_polling_enable) |
      .exchange.rollsite.polling.ids|=env(rollsite_polling_ids) |
      .exchange.rollsite.ips|=env(rollsite_ips) |
      .exchange.rollsite.enable=env(rollsite_enable)
    ' ${workdir}/files/fate_$role -I 2 -P   > ${base}/${pname:-fate}_$role

  ;;

  *)
    echo "Usage: $0 host|guest|exchange"
  ;;

  esac
}

def_process_file_core() {
    local role=$1
    local base=$2
    case $role in
      "host")
        echo '-----default_special_routes(host)----'
        def_format_special_routes host
        echo "temp_host_special_routes: ${temp_host_special_routes[*]}"
        host_special_routes=$( def_package_route temp_host_special_routes )
        echo "host_special_routes: ${host_special_routes[*]}"
        echo '-----default_routes(host)------------'
        host_default_routes="$(def_get_default_route host)"
        echo "host_default_routes:${host_default_routes}"
	echo "${host_default_routes}" | grep '},{'
	if [ "$?" -eq 0 ]
	then
          echo "warning: default routes number wrong"
	  exit 1
	fi
        echo "is_host_has_default_route:${is_host_has_default_route}"
        echo '-----role_self_routes(host)----------'
        def_format_role_self_routes host
        echo "role_self_routes: ${host_self_routes}"
        echo '-----render(host)--------------------'
        def_render_roles_core $role ${pname} $base
        echo "def_render_roles_core $role ${pname} ok"
      ;;

      "guest")
        echo '------default_special_routes(guest)---'
        def_format_special_routes guest
        echo "temp_guest_special_routes: ${temp_guest_special_routes[*]}"
        guest_special_routes=$( def_package_route temp_guest_special_routes )
        echo "guest_special_routes: ${guest_special_routes[*]}"
        echo '------default_routes(guest)------------'
        guest_default_routes="$(def_get_default_route guest)"
        echo "guest_default_routes:${guest_default_routes}"
	echo "${guest_default_routes}" | grep '},{'
	if [ "$?" -eq 0 ]
	then
          echo "warning: default routes number wrong"
	  exit 1
	fi

        echo "is_guest_has_default_route:${is_guest_has_default_route}"
        echo '------role_self_routes(guest)----------'
        def_format_role_self_routes guest
        echo "role_self_routes: ${guest_self_routes}"
        echo '------render(guest)-------------------'
        def_render_roles_core $role ${pname} $base
        echo "def_render_roles_core $role ${pname} ok"
      ;;
      "exchange")
        echo '------default_special_routes(exchange)---'
        def_format_special_routes exchange
        echo "temp_exchange_special_routes: ${temp_exchange_special_routes[*]}"
        exchange_special_routes=$( def_package_route temp_exchange_special_routes )
        echo "exchange_special_routes: ${exchange_special_routes[*]}"
        echo '------default_routes(exchange)-----------'
        exchange_default_routes="$( def_get_default_route exchange )"
        echo "exchange_default_routes: ${exchange_default_routes}"
        def_render_roles_core $role ${pname} $base
        echo "def_render_roles_core $role ${pname} ok"
      ;;

    esac
}

def_backup_configs() {
 local base=$1

 now=$( date "+%s" )
 bbase="${base}/backups/$now"
 [ ! -d "${bbase}" ] && mkdir -p ${bbase}/{environments,var_files}

 local num=$( ls ${base}/project-*.yaml 2>/dev/null |wc -l )
 [ $num -gt 0 ] && mv ${base}/project-*.yaml $bbase
 [ -d ${base}/environments/${deploy_env} ] && mv ${base}/environments/${deploy_env}  ${bbase}/environments/
 [ -d ${base}/var_files/${deploy_env} ] && mv ${base}/var_files/${deploy_env} ${bbase}/var_files
 mkdir -p ${base}/environments/${deploy_env}
 mkdir -p ${base}/var_files/${deploy_env}
}


def_simple_mode() {
  local arg=$1

  if [ "$arg" == "--help" ]
  then
    echo "Usage: $0 render"
    return
  fi

  echo "-------------------2 do backup------------------------------------"
  def_backup_configs $base
  echo "finish backup"
  echo "-------------------3 get role ips---------------------------------"
  def_get_role_ips host
  def_get_role_ips guest
  def_get_role_ips exchange

  echo "-------------------4 count fate data------------------------------"
  echo "-----deploy-----"
  echo "deploy_mode: ${deploy_mode}"
  echo "modules: ${modules[*]}"
  echo "-----partyid-----"
  echo "host: ${host_pid}"
  echo "guest: ${guest_pid}"
  echo "exchange: ${exchange_pid}"
  echo "-----ssl_roles-----"
  echo ${ssl_roles[*]}
  echo "-----info_ips-----"
  echo ${info_host_ips[*]}
  echo ${info_guest_ips[*]}
  echo ${info_exchange_ips[*]}
  echo "exchange: ${exchange_rollsite_ips[*]}"


  echo "-----node ips-----"
  for tt in  "rollsite" "clustermanager" "nodemanager" "fate_flow" "fateboard" "mysql";
  do
    eval echo "host_${tt}_ips: \${host_${tt}_ips[*]}"
    eval echo "guest_${tt}_ips: \${guest_${tt}_ips[*]}"
  done
  echo "exchange_rollsite_ips: ${exchange_rollsite_ips[*]}"
  echo "exchange_rollsite_ips: ${exchange_default_ips[*]}"



  echo "-------------------5 deal with route data--------------------------"
  for role in ${roles[*]};
  do
    echo "+++++++++++++++ deal with $role  +++++++++++++++"
    fbase="${base}/var_files/${deploy_env}"
    def_process_file_core $role $fbase

  done

  echo "-----------------6 render hosts  ------------------------------"
  dfile="${base}/environments/${deploy_env}/hosts"
  def_render_hosts $dfile
  echo "def_render_hosts $dfile ok"
  echo "-----------------7 render  base_init---------------------------"

  dfile="${base}/var_files/${deploy_env}/base_init"
  def_render_base_init $dfile
  echo "def_render_base_init $dfile ok"

  echo "-----------------8 render  playbooks---------------------------"
  dfile="${base}/project_${deploy_env}.yaml"
  def_render_playbook $dfile
  echo "def_render_playbook $dfile ok"

  echo "-----------------9 render  fate_init---------------------------"
  if [ "${#ssl_roles[*]}" == 1 ]
  then
    def_ssl_roles_adjust
  fi
  dfile="${base}/var_files/${deploy_env}/fate_init"
  def_render_fate_init $dfile
  echo "def_render_fate_init $dfile ok"
}

def_check_args() {
  local type=$1;
  local args=$2;
  case $type in
    "host")
      echo $args | grep -qE '^(-h=*[0-9]*:*[0-9.]*|-h)$'
      if [ "$?" -eq 1 ]
      then
        echo "check host:  $args unvid"
        return 1
      fi
    ;;
    "guest")
      echo $args | grep -qE '^(-g=*[0-9]*:*[0-9.]*|-g)$'
      if [ "$?" -eq 1 ]
      then
        echo "check guest:  $args unvid"
        return 1
      fi
      return $?
    ;;
    "exchange")
      echo $args | grep -qE '^(-e=*[0-9]*:*[0-9.]*|-e)$'
      if [ "$?" -eq 1 ]
      then
	pargs=( $( echo ${args#*=} | tr -s '|' ' ' ) )
	for parg in ${pargs[*]};
	do
	  echo $parg | grep -qE '^([0-9]*:[0-9.]*|[0-9.]*)$'
          if [ "$?" -eq 1 ]
	  then
            echo "check exchange:  $args unvid"
            return 1
          fi
	done
      fi
    ;;
    "mode")
      local deploy_mode=( "deploy" "install" "config" "uninstall" )
      echo ${deploy_mode[*]} | grep -wq  "${args#*=}"
      if [ "$?" -eq 1 ]
      then
        echo "check mode:  $args unvid"
        return 1
      fi
    ;;
    "engine")
      local engines=( "eggroll" "standalone" "spark" )
      echo ${engines[*]} | grep -wq  "${args#*=}"
      if [ "$?" -eq 1 ]
      then
        echo "check engines:  $args unvid"
        return 1
      fi
    ;;
    "key")
      echo $args | grep -qE '^-k=[a-z|]+$|^-k$'
      if [ "$?" -eq 0 ]
      then
	if [ "${args#*=}" == "${args%=*}" ]
	then
	  return 0
	fi
        local troles=( $( echo  ${args#*=} | tr -s '|' ' ' ) )
        for trole in ${troles[*]}
        do
          echo ${roles[*]} | grep -wq ${trole}
          if [ $? -eq 1 ]
          then
            echo "check key:  $args unvid"
            return 1
          fi
        done

      else
        return 1
      fi
    ;;
  esac

}

def_assist_mode() {
  local args=( $@ )
  echo "def_assist_mode: ${args[*]}"
  local roles=()
  deploy_mode="deploy"
  engines="eggroll"

  if [ ${#args[*]} == 0 ]; then
    args=( "--help" )
  fi

  last_check_arg=""
  for arg in ${args[*]};
  do
    case ${arg%=*} in
      "-h")
        local trole_info=${arg#*=}
        if [ "${arg#*=}" == "${arg%=*}" -o ${trole_info} == "-h" ]
        then
          roles=( ${roles[*]} "host:10000" )
          host_ips=( "default:192.168.0.1" )
        else
          def_check_args host $arg || return
          if [ "${trole_info#*:}" != "${trole_info%=*}" ]
          then
            roles=( ${roles[*]} "host:${trole_info%:*}" )
            host_ips=( "default:${trole_info#*:}" )
          else
            roles=( ${roles[*]} "host:10000" )
            host_ips=( "default:${trole_info}" )
          fi
        fi
      ;;
      "-g")
        local trole_info=${arg#*=}
        if [ "${arg#*=}" == "${arg%=*}" -o ${trole_info} == "-g" ]
        then
          roles=( ${roles[*]} "guest:9999" )
          guest_ips=( "default:192.168.0.2" )
        else
          def_check_args guest $arg || return
          if [ "${trole_info#*:}" != "${trole_info%=*}" ]
          then
            roles=( ${roles[*]} "guest:${trole_info%:*}" )
            guest_ips=( "default:${trole_info#*:}" )
          else
            roles=( ${roles[*]} "guest:9999" )
            guest_ips=( "default:${trole_info}" )
          fi
        fi
      ;;
      "-e")
        roles=( ${roles[*]} "exchange:0" )
        local trole_info=${arg#*=}
        if [ "${arg#*=}" == "${arg%=*}" -o ${trole_info} == "-e" ]
        then
          exchange_ips=( "default:192.168.0.99" )
        else
          def_check_args exchange $arg || return
          if [ "${trole_info}" != "-e" ]
          then
            exchange_ips=( "default:${trole_info#*:}" )
          else
            exchange_ips=( "default:192.168.0.99" )
          fi
        fi
      ;;
      "-m")
        def_check_args mode $arg || return
        if [ -n "${arg#*=}" ]
        then
          deploy_mode="${arg#*=}"
        fi
      ;;
      "-k")
	last_check_arg=$arg
        if [ "${arg#*=}" != "${arg%=*}" ]
        then
          ssl_roles=( $(  echo "${arg#*=}" | tr -s '|' ' ' ) )
        else
	  if [ "${#roles[*]}" -eq 2 -o "${#roles[*]}" -eq 1 ]
          then
	    for role in ${roles[*]};
	    do
              ssl_roles=( ${ssl_roles[*]} ${role%:*} )
            done
	  else
	    if [ "${#roles[*]}" -gt 2 ]
	    then
	      echo "ERROR: current roles: ${roles[*]} not support auto keys, for example: -k=\"host|exchange\""
	      exit 1
            fi
	  fi
        fi
      ;;
      "-n")
        def_check_args engine $arg || return
        if [ -n "${arg#*=}" ]
        then
          engines="${arg#*=}"
        fi
      ;;
      "--help")
        echo "Usage: $0 init -h|-g|-e|-m|-k"
        echo "     args:  "
        echo "         -h=ip or -h=\"partyid:ip\""
        echo "         -g=ip or -g=\"partyid:ip\""
        echo "         -e=ip"
        echo "         -m=deploy or install or config or uninstall"
        echo "         -k=both roles of keys(eg: host|guest)"
        echo "         -n=standalone or eggroll or spark（default： eggroll）"
        echo ""
        return
      ;;
      *)
	echo "arg: $arg wrong"
        echo "Usage: deploy.sh init -h|-g|-e|-m|-k|-n"
      ;;
    esac
  done

  if [ -n "$last_check_arg" ]
  then
    def_check_args key $last_check_arg || return
  fi

  def_render_setup

}

def_make_keys() {
name=$1

if [ "$#" -ne 1 ]
then
  echo "Usage: $0 [host|guest|exchange]"
  exit 1
fi

case $name in
  "host-guest"|"host-exchange"|"guest-host"|"guest-exchange"|"exchange-host"|"exchange-guest")
    rm -rf ${workdir}/keys/* && echo "clean ${workdir}/keys/*"
    aside=${name%-*}
    bside=${name#*-}

    echo $name
    curdir=${workdir}/keys/$name
    mkdir -p $curdir
    cd ${curdir}
    tpl="$( cat ${workdir}/tpl/ca-csr.json.tpl )"
    variables="ca_name=fate_$name"
    printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ca-csr.json
    cp ${workdir}/files/ca-config.json ${curdir}
    ${workdir}/bin/cfssl gencert -initca ca-csr.json | ${workdir}/bin/cfssljson -bare ca

    for side in $aside $bside
    do
      echo $side
      curdir=${workdir}/keys/$side
      mkdir -p $curdir
      cd ${curdir}
      cp -rf ${workdir}/keys/${name}/* .

      eval echo "**********${side}_rollsite_ips: \${${side}_rollsite_ips[0]}"
      tpl="$( cat ${workdir}/tpl/server-csr.json.tpl )"
      eval variables="\"server_cn=${side}-server.fate.fedai.org server_host=\${${side}_rollsite_ips[0]}\""
      echo "---------------$variables--------------"
      printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > server-csr.json
      ${workdir}/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | ${workdir}/bin/cfssljson -bare server
      openssl pkcs8 -topk8 -inform PEM -in server-key.pem     -outform PEM -out server.key -nocrypt

      tpl="$( cat ${workdir}/tpl/client-csr.json.tpl )"
      variables="client_cn=${side}-client.fate.fedai.org"
      printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > client-csr.json
      ${workdir}/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json | ${workdir}/bin/cfssljson -bare client
      openssl pkcs8 -topk8 -inform PEM -in client-key.pem     -outform PEM -out client.key -nocrypt
    done
  ;;
  "host"|"guest"|"exchange")
    echo $name
    curdir=${workdir}/keys/$name
    mkdir -p $curdir
    cd ${curdir}
    tpl="$( cat ${workdir}/tpl/ca-csr.json.tpl )"
    variables="ca_name=fate_$name"
    printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > ca-csr.json
    cp ${workdir}/files/ca-config.json ${curdir}
    ${workdir}/bin/cfssl gencert -initca ca-csr.json | ${workdir}/bin/cfssljson -bare ca

    tpl="$( cat ${workdir}/tpl/server-csr.json.tpl )"
    eval variables="\"server_cn=${name}-server.fate.fedai.org server_host=\${${name}_rollsite_ips[0]}\""
    echo "---------------$variables--------------"
    printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > server-csr.json
    ${workdir}/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | ${workdir}/bin/cfssljson -bare server
    openssl pkcs8 -topk8 -inform PEM -in server-key.pem     -outform PEM -out server.key -nocrypt

    tpl="$( cat ${workdir}/tpl/client-csr.json.tpl )"
    variables="client_cn=${name}-client.fate.fedai.org"
    printf "$variables\ncat << EOF\n$tpl\nEOF" | bash > client-csr.json
    ${workdir}/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json | ${workdir}/bin/cfssljson -bare client
    openssl pkcs8 -topk8 -inform PEM -in client-key.pem     -outform PEM -out client.key -nocrypt
  ;;

  *)
    echo "Usage: $0 host|guest|exchange|polling --server=polling_server_ip --client=polling_client_ip "
  ;;
esac
}

def_ssl_roles_adjust() {
  echo "ssl_roles adjust"
  if [ ${#ssl_roles[*]} != 1 ]
  then
    echo "only support ssl_roles has one member"
    exit 1
  fi

  case ${ssl_roles[0]} in
    "host"|"guest")
      ssl_roles=( "${ssl_roles[0]}" "exchange" )
    ;;
    "exchange")
      ssl_roles=( "${ssl_roles[0]}" "host" )
    ;;
  esac
}

def_main_process() {
  local action=$1

  case $action in

    "init")
      shift
      def_assist_mode $@

    ;;

    "render")
      echo "-------------------1 get base data--------------------------------"
      def_get_base_data || exit 1


      shift
      bash ${workdir}/check.sh &&  def_simple_mode $@
    ;;
    "ping")
      echo "-------------------1 get base data--------------------------------"
      def_get_base_data || exit 1
      echo "ping"
      ansible -i ${base}/environments/${deploy_env} $pname  -m ping

    ;;
    "deploy"|"install"|"config"|"uninstall")
      echo "-------------------1 get base data--------------------------------"
      def_get_base_data || exit 1
      now="$( date +%s )"
      mkdir -p ${base}/logs
      ansible-playbook -i ${base}/environments/${deploy_env}   ${base}/project_${deploy_env}.yaml >> ${base}/logs/${action}-${now}.log 2>&1 &
      echo "$action in progress, please check the log in ${base}/logs/${action}-${now}.log"
      echo "                            or commit \"tail -f  ${base}/logs/${action}-${now}.log\""
    ;;
    "keys")
      #echo "-------------------1 get base data--------------------------------"
      def_get_base_data || exit 1
      def_get_role_ips host
      def_get_role_ips guest
      def_get_role_ips exchange
      if [ -n "$2" ]
      then
        if [ "$2" == "--help" -o "$2" == "help" ]
        then
          echo "Usage: /bin/bash $0 keys [host|guest|exchange]"
        else
          def_make_keys $2
        fi
      else
        case  "${#ssl_roles[*]}" in
          1)
            def_ssl_roles_adjust
	    if [ "$?" -eq 0 ]
	    then
              dfile="${base}/var_files/${deploy_env}/fate_init"
              local ssl_roles_str="[$( echo ${ssl_roles[*]} | tr -s ' ' ',' )]"
              ssl_roles=${ssl_roles_str} ./bin/yq e '.ssl_roles=env(ssl_roles)' $dfile -I 2 -P > ${dfile}.2
	      mv ${dfile}.2 $dfile
              def_make_keys ${ssl_roles[0]}-${ssl_roles[1]} &&  /bin/bash ${workdir}/cp-keys.sh ${ssl_roles[0]} ${ssl_roles[1]}
	    fi
           ;;
          2)
            def_make_keys ${ssl_roles[0]}-${ssl_roles[1]} &&  /bin/bash ${workdir}/cp-keys.sh ${ssl_roles[0]} ${ssl_roles[1]}
           ;;
          *)
            echo "Waring: please setup ssl_roles correct";
            echo "Usage: /bin/bash $0 keys [host|guest|exchange]"
            ;;
        esac
      fi
    ;;
    "--help")
      echo "Usage: deploy.sh init|render|deloy|install|config|uninstall|keys|ping|help args"
    ;;
    *)
      echo "Usage: deploy.sh init|render|deloy|install|config|uninstall|keys|ping|help args"
    ;;

  esac
}

workdir=$(cd $(dirname $0); pwd)
base="${workdir}/.."
cd ${workdir}
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

def_main_process ${args[*]}



