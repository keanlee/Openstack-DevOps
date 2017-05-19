#!/bin/bash
#Wirte by keanlee on May 19th 

#------------------------------This script can help you depoly a lots of controller node and compute node 

ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"
MAGENTA="$ESC[0;35m"
YELLOW="$ESC[0;33m"
BLUE="$ESC[0;34m"
WHITE="$ESC[0;37m"
#PURPLE="$ESC[0;35m"
CYAN="$ESC[0;36m"

debug(){
if [[ $1 -ne 0 ]]; then
echo $RED $2 $NO_COLOR
exit 1
fi
}

function controller(){

echo "update later "

}

#---------------------------------main-----------------

function compute(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 
cat ./compute-hosts | while read line ; do scp -r deploy-openstack/ $line:/root/; debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./compute-hosts | while read line ; do ssh -n $line /bin/bash /root/deploy-openstack/install.sh compute ; debug "$?" "bash execute error "; done

}

compute 
