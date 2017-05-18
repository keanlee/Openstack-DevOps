#!/bin/bash
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
rabbitmqctl  delete_user openstack
rabbitmqctl  list_users
yum erase rabbitmq-server -y 1>/dev/null


yum erase openstack-keystone httpd mod_wsgi httpd-tools -y 1>/dev/null
yum erase python2-keystonemiddleware python2-keystoneauth1 python2-keystoneclient  -y 1>/dev/null
rm -rf /usr/share/keystone
rm -rf /etc/keystone
rm -rf /etc/httpd 
yum clean all 
