#!/bin/bash
#yum erase openstack-selinux python-openstackclient 1>/dev/null

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
rm -rf /etc/ntp.conf.rpmsave

rabbitmqctl  delete_user openstack
rabbitmqctl  list_users
yum erase rabbitmq-server -y 1>/dev/null
yum erase memcached python-memcached -y 1>/dev/null 
rm -rf /etc/sysconfig/memcached.rpmsave

yum erase openstack-keystone httpd mod_wsgi httpd-tools -y 1>/dev/null
yum erase python2-keystonemiddleware python2-keystoneauth1 python2-keystoneclient  -y 1>/dev/null
rm -rf /usr/share/keystone
rm -rf /etc/keystone
rm -rf /etc/httpd 
yum clean all

#--------------clean glance---------
yum erase openstack-glance 1>/dev/null 
rm -rf /etc/glance

#-------------clean nova for controller -------
yum erase openstack-nova-api openstack-nova-conductor \
openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler -y 
rm -rf /etc/nova  

#-----------clean nova for compute 
yum erase openstack-nova-compute -y 1>/dev/null 

#---------clean neutron for compute and controller 
yum erase openstack-neutron-linuxbridge ebtables ipset  -y 1>/dev/null 

yum erase openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables  -y 1>/dev/null 
rm -rf /etc/neutron

#--------clean cinder for controller --------

yum erase openstack-cinder -y 1>/dev/null 

 
