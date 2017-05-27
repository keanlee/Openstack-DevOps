#!/bin/bash 
#-------------------this script can be help you configuer the firewall rule for zabbix server ------
#author by lihao in March of 2017
STATUS=$(systemctl status firewalld | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')

function iptabels(){
#iptables -P INPUT DROP
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
#iptables -P INPUT DROP
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
#systemctl restart iptables
}

function firewalld(){
firewall-cmd --zone=public --add-port=80/tcp --permanent  1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=22/tcp --permanent  1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=10050/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=10051/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --reload  1>/dev/null 2>&1
}

if [[ $STATUS = active ]];then
firewalld
elif [ -f /etc/sysconfig/iptaables ];then
iptabels
else
continue
fi
echo -e "\e[1;32m Congratulation !!! You has been finished zabbix $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') install \e[0m"

