#!/bin/bash
# firwall will be update later 

#STATUS=$(systemctl status firewalld | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
#need add more for openstack env later 
function iptabels(){
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
#add rabbitmq port 
iptables -A  INPUT -p tcp --dport 5672 -j ACCEPT
#add rabbitmq web plugin port 
iptables -A  INPUT -p tcp --dport 15672 -j ACCEPT
#----------neutron-----------------------
iptables -A  INPUT -p tcp --dport 9696 -j ACCEPT
#----------keystone--------------------
iptables -A  INPUT -p tcp --dport 35357 -j ACCEPT
iptables -A  INPUT -p tcp --dport 5000 -j ACCEPT
#----------cinder---------------------
#cinderv2
iptables -A  INPUT -p tcp --dport 8776 -j ACCEPT
#------------glance---------------------
iptables -A  INPUT -p tcp --dport 9292 -j ACCEPT
#--------------nova--------------------
iptables -A  INPUT -p tcp --dport 8774 -j ACCEPT
#-------------zabbix agent -------------------
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
}

function firewalld(){
firewall-cmd --zone=public --add-port=80/tcp --permanent  1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=22/tcp --permanent  1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=10050/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=10051/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=5672/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=15672/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=9696/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=35357/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=5000/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=8776/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=9292/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=8774/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --reload  1>/dev/null 2>&1
}

#for now on 
echo $BLUE Disable the firewall $NO_COLOR
iptables -F
