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

SERVERIP=$2
function help(){ 
cat ./README.txt

cat 1>&2 <<__EOF__
$MAGENTA===========================================================================
         --------Usage as below ---------
         sh $0 controller zabbix-server-ip
            $BLUE#To deploy controller role host with zabbix-agent$NO_COLOR
         ${MAGENTA}sh $0 compute  zabbix-server-ip
            $BLUE#To deploy compute role host with zabbix-agent$NO_COLOR
         ${MAGENTA}sh $0 agent  zabbix-server-ip
            $BLUE#To agent role host with zabbix-agent$NO_COLOR
         ${MAGENTA}sh $0 all  zabbix-server-ip
            $BLUE#To deploy all role host  with zabbix-agent${MAGENTA}
         ${MAGENTA}sh $0 ssh-key-<target-hosts-role>
            $BLUE#to create ssh-key and copy it to tartget hosts 
            (target-hosts-role=controller,compute,agent)$NO_COLOR${MAGENTA}
===========================================================================$NO_COLOR
__EOF__

exit 0
}

debug(){
    if [[ $1 != 0 ]] ; then
        echo $RED error: $2 $NO_COLOR
        exit 1
    fi
}

function ssh_key(){
echo $BLUE Generating public/private rsa key pair,skip all steps by type Enter: $NO_COLOR
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
if [[ $1 = "compute" ]];then
    echo $BLUE copy public key to compute hosts:  $NO_COLOR
    for ips in $(cat ./compute);
        do ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
    done
elif [[ $1 = "controller" ]];then
    echo $BLUE copy public key to controller hosts: $NO_COLOR
    for ips in $(cat ./controller);
        do ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
   done
elif [[ $1 = "agent" ]];then
    echo $BLUE copy public key to network hosts:  $NO_COLOR
    for ips in $(cat ./agent);
        do ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
    done
elif [[ $1 = "storage" ]];then
    echo $BLUE copy public key to storage hosts:  $NO_COLOR
    for ips in $(cat ./storage);
        do ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
    done
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


#-------------------------------Main----------------------------
case $1 in 
all)
    controller
    compute
    agent 
    echo $BLUE Thank for you  use this script to install zabbix agent $NO_COLOR
    ;;
controller)
    controller
    ;;
compute)
    compute
    ;;
agent)
    agent
    ;;
ssh-key-controller)
    ssh_key controller
    ;;
ssh-key-compute)
    ssh_key compute
    ;;
ssh-key-agent)
    ssh_key agent
    ;;
*)
    help
esac  


