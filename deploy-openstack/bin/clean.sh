#!/bin/bash
#clean the env of openstack 
yum erase openstack-selinux python-openstackclient 1>/dev/null
echo $BLUE Begin clean the env ... $NO_COLOR

#rm -rf /etc/yum.repos.d/*
systemctl stop mariadb  1>/dev/null   
yum erase -y mariadb-* mariadb-libs 1>/dev/null   
yum erase -y python2-PyMySQL 1>/dev/null  
rm -rf /var/lib/mysql
rm -rf /usr/lib64/mysql
rm -rf /etc/my.cnf
rm -rf /etc/my.cnf.d
rm -rf /var/log/mariadb
rm -rf /usr/share/mariadb  
yum clean all   1>/dev/null   
yum erase ntp -y 1>/dev/null  
systemctl stop ntpd
rm -rf /etc/ntp.conf.rpmsave

rabbitmqctl  delete_user openstack 1>/dev/null   
rabbitmqctl  list_users  1>/dev/null   
systemctl stop rabbitmq-server
rm -rf /var/log/rabbitmq/
yum erase rabbitmq-server -y 1>/dev/null  

systemctl stop memcached 1>/dev/null   
yum erase memcached python-memcached -y 1>/dev/null 
rm -rf /etc/sysconfig/memcached.rpmsave

systemctl stop httpd 1>/dev/null   
yum erase openstack-keystone httpd mod_wsgi httpd-tools -y 1>/dev/null  
yum erase python2-keystonemiddleware python2-keystoneauth1 python2-keystoneclient  -y 1>/dev/null  
rm -rf /usr/share/keystone
rm -rf /etc/keystone
rm -rf /etc/httpd 
yum clean all  1>/dev/null   

#--------------clean glance---------
systemctl stop openstack-glance-api.service openstack-glance-registry.service  1>/dev/null   
yum erase openstack-glance 1>/dev/null  
rm -rf /etc/glance

#-------------clean nova for controller -------
systemctl stop  openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service   1>/dev/null   

yum erase openstack-nova-api openstack-nova-conductor \
openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler -y 1>/dev/null   
rm -rf /etc/nova  
rm -rf /var/log/nova
#-----------clean nova for compute 
systemctl stop openstack-nova-compute  1>/dev/null   
yum erase openstack-nova-compute -y 1>/dev/null   
yum erase qemu* -y 1>/dev/null
yum erase libvirt* -y 1>/dev/null
yum erase python-openvswitch* -y 1>/dev/null
yum erase openvswitch* -y 1>/dev/null

#---------clean neutron for compute and controller 
#openstack-neutron openstack-neutron-ml2

ovs-vsctl del-br br-ex 
ovs-vsctl del-br br-tun
ovs-vsctl del-br br-int

systemctl stop neutron-server neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service  openvswitch.service \
neutron-l3-agent.service   1>/dev/null 
yum erase openstack-neutron-linuxbridge ebtables ipset  -y 1>/dev/null  
yum erase openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch  -y 1>/dev/null  
yum erase openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables  -y 1>/dev/null   
rm -rf /etc/neutron
rm -rf /var/log/neutron
#--------clean cinder for controller and compute --------
yum erase openstack-cinder -y 1>/dev/null   
yum erase lvm2 openstack-cinder targetcli python-keystone  -y 1>/dev/null  
rm -rf /etc/cinder 

rm -rf /var/log/glance/
rm -rf /var/log/httpd/
rm -rf /var/log/cinder/
rm -rf /var/log/openvswitch/
rm -rf /etc/openstack-dashboard/ 
rm -rf /etc/openvswitch/ 


