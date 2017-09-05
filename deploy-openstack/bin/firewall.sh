#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License
#
# firwall will be update later 

#STATUS=$(systemctl status firewalld | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
#need add more for openstack env later 
#refer https://docs.openstack.org/admin-guide/firewalls-default-ports.html
#example for iptables:
#  iptables --append INPUT --in-interface eth0 \
#  --protocol tcp --match tcp --dport ${PORT} \
#  --source ${NODE-IP-ADDRESS} --jump ACCEPT

#https://fedoraproject.org/wiki/How_to_edit_iptables_rules

function iptabels(){
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT

#For Galera mariadb 
#On 3306, Galera Cluster uses TCP for database client connections and State Snapshot Transfers methods that require the client, (that is, mysqldump).
#On 4567, Galera Cluster uses TCP for replication traffic. Multicast replication uses both TCP and UDP on this port.
#On 4568, Galera Cluster uses TCP for Incremental State Transfers.
#On 4444, Galera Cluster uses TCP for all other State Snapshot Transfer methods.
iptables -A  INPUT -p tcp --dport 3306 -j ACCEPT
iptables -A  INPUT -p tcp --dport 4567 -j ACCEPT
iptables -A  INPUT -p tcp --dport 4568 -j ACCEPT
iptables -A  INPUT -p tcp --dport 4444 -j ACCEPT
iptables -A  INPUT -p tcp --dport 9200 -j ACCEPT


#----------------for haproxy -----------
iptables -A  INPUT -p tcp --dport 8888  -j ACCEPT
iptables -A  INPUT -p tcp --dport 10000 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10002 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10004 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10006 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10008 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10010 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10012 -j ACCEPT

if [[ $1 = "controller" ]];then 
#-------------------add rabbitmq port 
    iptables -A  INPUT -p tcp --dport 5672 -j ACCEPT
#-------------------add rabbitmq web plugin port 
    iptables -A  INPUT -p tcp --dport 15672 -j ACCEPT
#--------------------memcached
    iptables -A  INPUT -p tcp --dport 11211 -j ACCEPT

    iptables -A  INPUT -p tcp --dport 80 -j ACCEPT
#--------------nova--------------------
    iptables -A  INPUT -p tcp --dport 8774 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 8775 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 6080 -j ACCEPT
#----------neutron-----------------------
    iptables -A  INPUT -p tcp --dport 9696 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 3260 -j ACCEPT
#----------cinder---------------------
    iptables -A  INPUT -p tcp --dport 8776 -j ACCEPT
#------------glance---------------------
    iptables -A  INPUT -p tcp --dport 9292 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 9191 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 6200,6201,873 -j ACCEPT
#----------keystone--------------------
    iptables -A  INPUT -p tcp --dport 5000,35357 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 4789 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 11211 -j ACCEPT
    iptables -A  INPUT -p tcp --dport 8777 -j ACCEPT
    iptables-save > /etc/sysconfig/iptables
fi

#for compute 
iptables -A  INPUT -p tcp --dport 16509 -j ACCEPT
iptables -A  INPUT -p tcp --dport 5900 -j ACCEPT
iptables -A  INPUT -p tcp --dport 4789 -j ACCEPT

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
firewall-cmd --zone=public --add-port=11211/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=3306/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=4567/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=4568/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=4444/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --reload  1>/dev/null 2>&1
}

#for now on 
echo $BLUE Disable the firewall $NO_COLOR
iptables -F
