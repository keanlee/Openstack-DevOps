#!/bin/bash
#author by keanlee on May 15th of 2017 

cd $(cd $(dirname $0); pwd)
source ./bin/common.sh

README=$(cat ./README.txt)
echo $GREEN $README $NO_COLOR 
echo $GREEN This script will be deploy OpenStack on ${NO_COLOR}${YELLOW}$(cat /etc/redhat-release) $NO_COLOR

help(){
cat 1>&2 <<__EOF__
$MAGENTA================================================================
            --------Usage as below ---------
             sh $0 install controller
             sh $0 install compute
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
source ./bin/compute.sh compute
sleep 5
source ./bin/neutron.sh compute
sleep 5
source ./bin/cinder.sh  compute 
;;
*)
help
;;
esac




