#!/bin/bash
#Author by keanlee on May 11th of 2017

# ansi colors for formatting heredoc
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

function NET_NAME_IP(){
#This function can list your network card with it's ip address 

cat 1>&2 <<__EOF__
$MAGENTA----------------------------------------------------------------
     Network Cards on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} list below: 
----------------------------------------------------------------
$NO_COLOR
__EOF__

NET_DEV_NAME=$(cat /proc/net/dev | awk '{print $1}' | sed -n '3,$p' | awk -F ":" '{print $1}' | grep -v ^lo$ | grep -v ^macvtap* | grep -v ^tap* | grep -v ^q | grep -v ^virbr* | grep -v ^vnet )
#                                                                                              except the lo and   virtual cards:     macvtap      network name 
for i in $NET_DEV_NAME
    do
        NET_RUN_STATUS=$(ip addr show $i | sed -n '1p' | awk '{print $9}')

        if [[ $NET_RUN_STATUS = 'DOWN' ]];then
            continue
        else
            echo ${BLUE} The network card Name:${NO_COLOR}$YELLOW $i${NO_COLOR} ${BLUE},the network card status:$GREEN $NET_RUN_STATUS $NO_COLOR
        fi
        
        IP_ADDR=$(ip addr show $i | grep 'inet[^6]' | sed -n '1p' | awk '{print $2}' | awk -F "/" '{print $1}')
        echo ${BLUE} The IP address is:$NO_COLOR$GREEN $IP_ADDR $NO_COLOR

           if [[ $IP_ADDR = "" ]];then
              echo $RED No IP Address with $i $NO_COLOR
           fi
done
}

function DISK_INFO(){
cat 1>&2 <<__EOF__
$MAGENTA----------------------------------------------------------------
     Disk info on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} list below: 
----------------------------------------------------------------
$NO_COLOR
__EOF__

DEVICE=$(cat /proc/partitions | awk '{print $4}' | sed -n '3,$p' | grep "[a-z]$")

for DEVICE_ID in $DEVICE
    do 
        DISK_SIZE=$(lsblk /dev/${DEVICE_ID} | sed -n '2p' | awk '{print $4}')
        echo $BLUE Disk name: ${YELLOW}$DEVICE_ID${NO_COLOR} $BLUE the size is:$GREEN $DISK_SIZE${NO_COLOR}
        
done
}

function CPU_MEM(){
cat 1>&2 <<__EOF__
$MAGENTA----------------------------------------------------------------
     CPUs and MEMs info on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} list below: 
----------------------------------------------------------------
$NO_COLOR
__EOF__

if [[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) = 0 ]];then
    echo $YELLOW Your host does not support hardware acceleration $NO_COLOR
    echo $YELLOW $(lscpu | grep ^Hypervisor) $NO_COLOR
else 
    echo $GREEN Your host support hardware acceleration $NO_COLOR
fi

CPUs=$(lscpu | grep ^CPU\(s\) | awk -F ":" '{print $2}')
echo $BLUE Your OS CPU\(s\) is: $NO_COLOR $GREEN${CPUs}$NO_COLOR

MEMs=$(free -m | grep -i mem | awk '{print $2 "M"}')
echo $BLUE Your OS total Mem:$NO_COLOR $GREEN${MEMs}$NO_COLOR
}


#----------------------------Main-----------------------------------
cat 1>&2 <<__EOF__
$CYAN===================================================================
    ############## HOSTNAME: $YELLOW$(hostname)${CYAN} ###############
===================================================================
$NO_COLOR
__EOF__
echo $BLUE Your linux distribution: ${NO_COLOR}${GREEN}$(cat /etc/redhat-release) $NO_COLOR

CPU_MEM
NET_NAME_IP
DISK_INFO

