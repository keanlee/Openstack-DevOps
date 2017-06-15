#!/bin/bash
#Tue Apr 25 13:24:29 CST 2017
#sed -i "s/METADATA=/METADATA=compute/g" install-agent.sh
#autor by keanlee
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

SERVERIP=$1
if [ $# = 0 ];then 
    cat ./README.txt
    echo $CYAN Usage: sh $0 zabbix-server-ip $NO_COLOR
    exit 0
fi 

debug(){
    if [[ $1 != 0 ]] ; then
        echo $RED error: $2 $NO_COLOR
        exit 1
    fi
}

#------------------Function for controller node deploy zabbix agent ---------------------------------
function controller(){
local METADATA
METADATA=controller   #change this for your request 
echo $BLUE Beginning install zabbix agent on $YELLOW $METADATA  $NO_COLOR
cat ./$METADATA | while read line ; do scp -r install-zabbix-agent/ $line:/root/; debug $? ; done   1>/dev/null 2>&1 

cat ./$METADATA | while read line ; do ssh -n $line /bin/bash /root/install-zabbix-agent/install-agent.sh \
$SERVERIP $METADATA ;debug $? ;done  2>/dev/null

cat ./$METADATA | while read line ; do ssh -n $line  'rm -rf /root/install-zabbix-agent/' ;done 
echo $GREEN Finished install zabbix agent on host: $YELLOW  $(cat ./$METADATA) $NO_COLOR
}


#------------------Function for compute node deploy zabbix agent --------------------------------------
function compute(){
local METADATA
METADATA=compute    #change this for your request
echo $BLUE Beginning install zabbix agent on $YELLOW $METADATA  $NO_COLOR
cat ./$METADATA | while read line ; do scp -r install-zabbix-agent/ $line:/root/; debug $? ; done  1>/dev/null 2>&1
    
cat ./$METADATA | while read line ; do ssh -n $line /bin/bash /root/install-zabbix-agent/install-agent.sh \
$SERVERIP $METADATA ;debug $? ;done  2>/dev/null
 
cat ./$METADATA | while read line ; do ssh -n $line 'rm -rf /root/install-zabbix-agent/';done 
echo $GREEN Finished install zabbix agent on host: $YELLOW  $(cat ./$METADATA) $NO_COLOR
}

function agent(){
local METADATA
METADATA=agent   #change this for your request
echo $BLUE Beginning install zabbix agent on $YELLOW $METADATA  $NO_COLOR
cat ./$METADATA | while read line ; do scp -r install-zabbix-agent/ $line:/root/; debug $? ; done  1>/dev/null 2>&1

cat ./$METADATA | while read line ; do ssh -n $line /bin/bash /root/install-zabbix-agent/install-agent.sh \
$SERVERIP $METADATA ;debug $? ;done  2>/dev/null

cat ./$METADATA | while read line ; do ssh -n $line 'rm -rf /root/install-zabbix-agent/';done
echo $GREEN Finished install zabbix agent on host: $YELLOW  $(cat ./$METADATA) $NO_COLOR
}
controller
compute
agent 
echo $BLUE Thank for you  use this script to install zabbix agent $NO_COLOR

