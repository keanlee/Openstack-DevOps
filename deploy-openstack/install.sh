#!/bin/bash
#author by keanlee on May 15th of 2017 

cd $(cd $(dirname $0); pwd)
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
source ./variable 
help(){
echo $RED --------Usage as below ---------  $NO_COLOR    
    echo  $BLUE sh $0 install controller $NO_COLOR  
    echo  $BLUE sh $0 install ha_proxy  $NO_COLOR
    echo  $BLUE sh $0 install compute   $NO_COLOR
 
}

if [[ $# = 0 || $# -gt 1 ]]; then 
help
fi

debug(){
if [[ $1 -ne 0 ]]; then 
echo $RED Faild install package, please check your yum repos $NO_COLOR 
exit 1
fi
}

function ntp()
{
    yum install ntp -y
    cat /etc/ntp.conf |grep "server $NTP_SERVER_IP iburst" || {
        cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        ntpdate $NTP_SERVER_IP
        log_out "$?" "ntp time sync from server "
        sed -i "/server 0.centos.pool.ntp.org iburst/a\server $NTP_SERVER_IP iburst" /etc/ntp.conf
        sed -i "/server 0.centos.pool.ntp.org iburst/d" /etc/ntp.conf
        sed -i "/server 1.centos.pool.ntp.org iburst/d" /etc/ntp.conf
        sed -i "/server 2.centos.pool.ntp.org iburst/d" /etc/ntp.conf
        sed -i "/server 3.centos.pool.ntp.org iburst/d" /etc/ntp.conf
        systemctl enable ntpd.service && systemctl start ntpd.service
        log_out "$?" "systemctl start ntp.service"
    }
}



