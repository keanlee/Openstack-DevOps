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

yum erase rabbitmq-server -y 1>/dev/null
yum erase openstack-keystone httpd mod_wsgi  -y 1>/dev/null
rm -rf /etc/keystone 
