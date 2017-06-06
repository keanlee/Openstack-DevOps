#!/bin/bash
#author by keanlee on May 15th of 2017 

cd $(cd $(dirname $0); pwd)
source ./bin/common.sh

echo -e $CYAN $(cat ./README.txt) $NO_COLOR 
echo $GREEN This script will be deploy OpenStack on ${NO_COLOR}${YELLOW}$(cat /etc/redhat-release) $NO_COLOR

function help(){
cat 1>&2 <<__EOF__
$MAGENTA================================================================
            --------Usage as below ---------
             sh $0 controller
             sh $0 compute
             sh $0 network
             sh $0 check 
================================================================
$NO_COLOR
__EOF__
}

if [[ $# = 0 || $# -gt 1 ]]; then 
    help
    exit 1
fi



#---------------compnment choose -----------
case $1 in
controller)
source ./bin/clean.sh 
sleep 2
yum_repos
initialize_env
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
source ./bin/clean.sh 
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
source ./bin/clean.sh 
yum_repos
initialize_env
ntp
source ./bin/firewall.sh
source ./bin/neutron.sh network
;;
check)
source ./bin/net_and_disk_info.sh
;;
*)
help
;;
esac


