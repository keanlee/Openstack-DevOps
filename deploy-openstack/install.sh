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
             sh $0 check 
================================================================
$NO_COLOR
__EOF__
}

if [[ $# = 0 || $# -gt 1 ]]; then 
    help
    exit 1
fi

function yum_repos(){
if [[ ! -d /etc/yum.repos.d/bak ]];then
    mkdir /etc/yum.repos.d/bak
else 
    mv /etc/yum.repos.d/* /etc/yum.repos.d/bak/
    cp ./repos/* /etc/yum.repos.d/
    yum clean all
    echo $GREEN yum repos config done $NO_COLOR
fi
}



#---------------compnment choose -----------
case $1 in
controller)
yum_repos
source ./bin/clean.sh
sleep 2
mysql_configuration

source ./bin/keystone.sh
sleep 5
source ./bin/glance.sh
sleep 5
source ./bin/nova.sh controller  
sleep 5
source ./bin/neutron.sh controller 
sleep 5
source ./bin/cinder.sh controller
sleep 5
source ./bin/dashboard.sh 
;;

compute)
source ./bin/clean.sh 
sleep 2
yum_repos
source ./bin/nova.sh compute
sleep 5
source ./bin/neutron.sh compute
sleep 5
source ./bin/cinder.sh  compute 
;;

check)
source ./bin/net_and_disk_info.sh
;;
*)
help
;;
esac


