#!/bin/bash
#author by keanlee on May 15th of 2017 

cd $(cd $(dirname $0); pwd)
source ./bin/common.sh

echo $GREEN This script will be deploy OpenStack on ${NO_COLOR}${YELLOW}$(cat /etc/redhat-release) $NO_COLOR

function help(){
cat 1>&2 <<__EOF__
$MAGENTA================================================================
            --------Usage as below ---------
             sh $0 controller
             sh $0 compute
             sh $0 network
             sh $0 check
             sh $0 controller-as-network-node
             sh $0 compute-as-network-node 
================================================================
$NO_COLOR
__EOF__
}

if [[ $# = 0 || $# -gt 1 ]]; then 
    echo -e $CYAN $(cat ./README.txt) $NO_COLOR 
    help
    exit 1
fi



#---------------compnment choose -----------
case $1 in
    controller)
    #source ./bin/clean.sh 
    yum_repos
    initialize_env
    common_packages
    ntp
    source ./bin/firewall.sh
    rabbitmq_configuration
    memcache
    mysql_configuration
    source ./bin/keystone.sh
    sleep 2
    source ./bin/glance.sh
    sleep 2
    source ./bin/nova.sh controller  
    sleep 2
    source ./bin/neutron.sh controller 
    sleep 2
    source ./bin/cinder.sh controller
    sleep 2
    source ./bin/dashboard.sh 
    ;;
compute)
    #source ./bin/clean.sh 
    yum_repos
    initialize_env
    ntp
    source ./bin/firewall.sh
    sleep 2
    source ./bin/nova.sh compute
    sleep 2
    source ./bin/neutron.sh compute
    #source ./bin/cinder.sh  compute 
    ;;
network) 
    yum_repos
    initialize_env
    ntp
    source ./bin/firewall.sh
    source ./bin/neutron.sh network
    ;;
controller-as-network-node)
    source ./bin/clean.sh 
    yum_repos
    initialize_env
    ntp
    common_packages
    source ./bin/firewall.sh
    rabbitmq_configuration
    memcache
    mysql_configuration
    source ./bin/keystone.sh
    source ./bin/glance.sh
    source ./bin/nova.sh controller  
    source ./bin/neutron.sh controller-as-network-node
    source ./bin/cinder.sh controller
    source ./bin/dashboard.sh 
    #source ./bin/initial_network.sh
    ;;
compute-as-network-node)
    #source ./bin/clean.sh 
    yum_repos
    initialize_env
    ntp
    source ./bin/firewall.sh
    sleep 2
    source ./bin/nova.sh compute
    sleep 2
    source ./bin/neutron.sh compute
    source ./bin/neutron.sh compute-as-network-node
    #source ./bin/cinder.sh  compute 
    ;;
check)
    source ./bin/system_info.sh
    ;;
*)
   help
   ;;
esac


