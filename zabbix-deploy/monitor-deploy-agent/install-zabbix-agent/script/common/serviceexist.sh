#!/bin/sh 
#author by keanlee on Feb 20th
#this script can be display deamon which is you type if running 

STATUS=$(systemctl status $1 | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
if [[ $STATUS == "active" ]]; then
    echo "1" #daemon is running 
else
    echo "0" #daemon is down
fi
