#!/bin/bash

STATUS=$(systemctl status firewalld | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
#need add more for openstack env later 
function iptabels(){
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
#add rabbitmq port 
iptables -A  INPUT -p tcp --dport 5672 -j ACCEPT
#add rabbitmq web plugin port 
iptables -A  INPUT -p tcp --dport 15672 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
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
else
iptables
fi
