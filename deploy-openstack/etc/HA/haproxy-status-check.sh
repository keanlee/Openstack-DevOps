#!/bin/bash
HA_PROXY_STATUS=$(ps -C haproxy --no-header | wc -l )

if [[  $HA_PROXY_STATUS -eq 0 ]];then 
    systemctl start haproxy
    sleep 4
    if [[ $HA_PROXY_STATUS -eq 0  ]];then 
        ystemctl stop keepalived
    fi
fi 

