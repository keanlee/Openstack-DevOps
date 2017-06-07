#!/bin/sh
#author by keanlee on 13th Oct of 2016
#wget -r -p -np -k -P ./ http://110.76.187.145/repos/
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

function debug(){
if [[ $1 -ne 0 ]]; then
echo $RED ERROR:  $2 $NO_COLOR
exit 1
fi
}



README=$(cat ./README.txt)
OS=$(cat /etc/redhat-release | awk '{print $1}')
if [ $OS = Red ];then
    OSVERSION=$(cat /etc/redhat-release | awk '{print $7}' | awk -F "." '{print $2}')
else
    OSVERSION=$(cat /etc/redhat-release | awk '{print $4}' | awk -F "." '{print $2}')
fi
    echo $BLUE $README $NO_COLOR

function install(){
#echo -e " \033[1m Begin install zabbix server  ..."
echo -e "\e[1;36m Begin install zabbix server  ... \e[0m"
#mkdir /etc/yum.repos.d/bak
#mv /etc/yum.repos.d/*  /etc/yum.repos.d/bak/  1>/dev/null 2>&1 
rm -rf /etc/yum.repos.d/* 

#--------------------this functin is setup the yum repo, you can change the repo on ./repo dir
cp ./repo/* /etc/yum.repos.d/
#cp ./repo/zabbix3.0.repo   /etc/yum.repos.d/
yum clean all 1>/dev/null 2>&1
echo -e "\e[1;36m setup zabbix repos successfull \e[0m"

#------------------execute the install script --------
source ./bin/install.sh 
source ./bin/firewall.sh
echo -e "\e[1;32m ----->Please Go Ahead Zabbix frontend to finished install zabbix server \e[0m"
echo -e "\e[1;32m ----->PLEASE Login as Admin/zabbix in IP/zabbix by your Browser \e[0m"
}

function choice(){
            if [ $1 -eq 1 ];then
#--------------Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon
            rpm -Uvh --force ./packages/gnutls-3.1.18-8.el7.x86_64.rpm 1>/dev/null &&
            echo "This script will be deploy zabbix-server on $GREEN $(cat /etc/redhat-release) $NO_CLOLOR"
            install
            else
            echo "This script will be deploy zabbix-server on $GREEN $(cat /etc/redhat-release) $NO_CLOLOR"
            install
            fi
}

if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
source ./bin/clean.sh
choice $OSVERSION
else
choice $OSVERSION
fi
