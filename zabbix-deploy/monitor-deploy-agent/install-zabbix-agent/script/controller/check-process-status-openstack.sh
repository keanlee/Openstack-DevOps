#!/bin/bash 
#write by 2016-8-14
source  /etc/zabbix/scripts/admin-openrc

case $1 in
nova)
    process_status=$($1 service-list  | awk -F '|' '{print  $3 $4 $7}' | grep down | awk '{print $2": "$1}')
    if [[ $process_status = "" ]]; then
        echo 1
    else
        echo $process_status
    fi
    ;;
neutron)
    process_status=$($1 agent-list | awk -F '|' '{print $4 $6 $8 }' | grep xxx | awk '{print $1 ": "$3 }')
    if [[ $process_status = "" ]]; then
        echo 1
    else
        echo $process_status
    fi
    ;;
cinder)
    process_status=$($1 service-list | awk -F '|' '{print $2 $3 $6}' | grep down | awk '{print $2": "$1}' )
    if [[ $process_status = "" ]]; then
        echo 1 
    else
        echo $process_status
    fi
    ;;
esac
