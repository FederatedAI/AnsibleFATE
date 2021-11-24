# This is the default ansible 'hosts' file.
#
# It should live in /etc/ansible/hosts
#
#   - Comments begin with the '#' character
#   - Blank lines are ignored
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups

# Ex 1: Ungrouped hosts, specify before any group headers.

[all:vars]
ansible_connection=ssh
ansible_ssh_port=${ssh_port}
ansible_ssh_user=${user}
#ansible_ssh_pass=
##method: sudo or su
ansible_become_method=sudo
ansible_become_user=root
ansible_become_pass=

[deploy_check]
${deploy_check_ip}

[${pname}]

#
