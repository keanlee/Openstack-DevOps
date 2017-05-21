#!/bin/bash
#author by keanlee on May 15th of 2017 

cd $(cd $(dirname $0); pwd)
source ./bin/common.sh

README=$(cat ./README.txt)
echo $GREEN $README $NO_COLOR 
echo $GREEN This script will be deploy OpenStack on ${NO_COLOR}${YELLOW}$(cat /etc/redhat-release) $NO_COLOR

help(){
echo $MAGENTA --------Usage as below ---------  $NO_COLOR    
    echo  $BLUE sh $0 install controller $NO_COLOR  
    echo  $BLUE sh $0 install ha_proxy  $NO_COLOR
    echo  $BLUE sh $0 install compute   $NO_COLOR
 
}

if [[ $# = 0 || $# -gt 1 ]]; then 
help
exit 1
fi


#---------------compnment choose -----------
case $1 in
controller)
mysql_configuration
source ./bin/keystone.sh
sleep 5
source ./bin/glance.sh
sleep 5
source ./bin/compute.sh controller  
sleep 5
source ./bin/neutron.sh controller 
sleep 5
source ./bin/dashboard.sh 
sleep 5 
source ./bin/cinder.sh controller
;;
compute)
source ./bin/compute.sh compute
source ./bin/neutron.sh compute
#update cinder later 
;;
*)
help
;;
esac




