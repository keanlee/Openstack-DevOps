#!/bin/bash 
#codeing in  2017
#author by KeanLee

cd $(cd `dirname $0`; pwd)

ZABBIXSERVER=$1                    #zabbix server ip 
HOSTNAME=$(hostname)                         #hostname will be display on zabbix server web page 
METADATA=$2                                   #For Openstack option is controller/compute/ceph/other roles,this will be used for auto Auto registration

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


debug(){
    if [[ $1 != 0 ]] ; then
        echo $RED error: $2 $NO_COLOR
        exit 1
    fi
}

function install(){
#-----------------Disable selinux-----------------
if [[ $(getenforce) = Enforcing ]];then
    echo $BLUE Disable selinux $NO_COLOR
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 
    setenforce 0  &&
    echo $GREEN Disable the selinux by config file. The current selinux Status:$NO_COLOR $YELLOW $(getenforce) $NO_COLOR

elif [[ $(getenforce) =  Permissive ]];then 
    echo $BLUE Disable selinux $NO_COLOR
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    echo $GREEN Disable the selinux by config file. The current selinux Status:$NO_COLOR $YELLOW $(getenforce) $NO_COLOR
fi

#---------------install package of zabbix agent -----
rpm -ivh ./packages/zabbix-agent* 1>/dev/null 2>&1 &&

#--------------configuer the conf file of zabbix agent -----------
sed -i "s/Server=127.0.0.1/Server=$ZABBIXSERVER/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=$ZABBIXSERVER/g"  /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/g"  /etc/zabbix/zabbix_agentd.conf
sed -i "167 i HostMetadata=$METADATA"  /etc/zabbix/zabbix_agentd.conf

#--------------iptables setip------
STATUS=$(systemctl status firewalld | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
if [[ $STATUS = active ]];then
    firewall-cmd --zone=public --add-port=10050/tcp --permanent 1>/dev/null 2>&1
    firewall-cmd --reload  1>/dev/null 2>&1
else
    iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
    iptables-save > /etc/sysconfig/iptables
fi

#--------------add daemon iteam script for each host------------------- 
mkdir -p /etc/zabbix/scripts
cp ./script/common/serviceexist.sh /etc/zabbix/scripts
sed -i '294 i  UserParameter=openstack.serviceexist[*],/etc/zabbix/scripts/serviceexist.sh $1 ' /etc/zabbix/zabbix_agentd.conf

#--------------For openstack controller item ---------
if [ $METADATA = controller ];then
    cp  /home/admin-openrc  /etc/zabbix/scripts
    cp ./script/controller/check-process-status-openstack.sh  /etc/zabbix/scripts
    sed -i '295 i UserParameter=check-process-status-openstack[*],/etc/zabbix/scripts/check-process-status-openstack.sh $1 ' /etc/zabbix/zabbix_agentd.conf
else 
    continue 
fi 

#--------------add ceph support -------------------------
if [ $METADATA = ceph ];then
    usermod -a -G ceph zabbix
fi

#--------------end install zabbix agent---------------------
chown -R zabbix:zabbix /etc/zabbix/scripts
chmod 700 /etc/zabbix/scripts/*
systemctl enable zabbix-agent 1>/dev/null 2>&1  
systemctl start zabbix-agent &&
    debug "$?" "Start zabbix-agent daemon failed,did you set the selinux off ? "
echo -e "\e[1;32m Zabbix agent has been install on $YELLOW $(hostname) $NO_COLOR  \e[0m "
echo -e "\e[1;32m You can go to the zabbix server page to add $YELLOW $(hostname) $NO_COLOR  \e[0m "
echo -e "\e[1;32m The metadata  is $YELLOW $METADATA $NO_COLOR   \e[0m "
}

#--------------------clean agent env ----------
function clean(){
      echo -e "\e[31m Begin clean zabbix agent installed env ...\e[0m "
      yum erase zabbix-agent zabbix-sender -y  1>/dev/null 2>&1
      rm -rf /etc/zabbix
      echo -e "\e[32m Finshed clean env \e[0m"
      }

if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
    clean
    install
else
    install
fi
