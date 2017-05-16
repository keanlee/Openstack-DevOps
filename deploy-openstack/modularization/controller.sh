#!/bin/bash

function packages_of_controller(){
#-----------------install all of package of controller node ------------------------------------
echo $BLUE Beginning install packages of controller node On $(hostname) , please be wait ... $NO_COLOR 
    
 yum install openstack-selinux python-openstackclient -y 1>/dev/null 
    debug "$?" "$RED Install openstack-selinux python-openstackclient failed $NO_COLOR"
    
 yum install openstack-keystone httpd mod_wsgi  memcached python-memcached -y 1>/dev/null
    debug "$?" "$RED Install openstack-keystone failed $NO_COLOR"
    
 yum install openstack-glance  -y  1>/dev/null
    debug "$?" "$RED Install openstack-glance failed $NO_COLOR"
    
 yum install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler -y 1>/dev/null
    debug  "$?" "$RED Install openstack-nova-api failed $NO_COLOR"
    
 yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch -y 1>/dev/null
    debug  "$?" "$RED Install openstack-neutron failed $NO_COLOR"
    
 yum install openstack-dashboard  -y 1>/dev/null
    debug  "$?" "$RED Install openstack-dashboard failed $NO_COLOR"
   
 yum install openstack-cinder  -y 1>/dev/null
    debug  "$?" "$RED Install openstack-cinder failed $NO_COLOR"
   
 yum install openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central python-ceilometerclient -y 1>/dev/null
    debug  "$?" "$RED Install ceilometer failed $NO_COLOR"
   
 yum install python-rbd -y 1>/dev/null
    debug  "$?" "$RED Install python-rbd failed $NO_COLOR "

echo $GREEN Finshed install all packages of controller on $YELLOW $(hostname) $NO_COLOR 
}

function mysql_configuration(){
echo $BLUE Beginning configuration mysql for controller node on $YELLOW $(hostname) $NO_COLOR
# set the bind-address key to the management IP address of the controller node to enable access by other nodes via the management network
# refer https://docs.openstack.org/newton/install-guide-rdo/environment-sql-database.html
yum install mariadb mariadb-server python2-PyMySQL -y 1>/dev/null 
debug "$1" "$RED Install mariadb mariadb-server python2-PyMySQL failed $NO_COLOR"   
    echo > /etc/my.cnf.d/openstack.cnf
    cat > /etc/my.cnf.d/openstack.cnf <<EOF
[mysqld]
bind-address = $MGMT_IP
default-storage-engine = innodb
innodb_file_per_table
max_connections=4096
collation-server = utf8_general_ci
character-set-server = utf8
init-connect = 'SET NAMES utf8'
EOF
systemctl enable mariadb.service 1>/dev/null && 
systemctl start mariadb.service
#sed -i '/Group=mysql/a\LimitNOFILE=65535' /usr/lib/systemd/system/mariadb.service
#systemctl daemon-reload
systemctl restart mariadb.service

mysql_secure_installation <<EOF

y
$MARIADB_PASSWORD
$MARIADB_PASSWORD
y
y
y
y
EOF
debug "$?" "$RED Mysql configuration failed $NO_COLOR"
echo $GREEN Finished the Mariadb install and configuration on $YELLOW $(hostname) $NO_COLOR 
}

function rabbitmq_configuration(){
#RABBIT_PASS  
#Except Horizone and keystone ,each component need connect to Rabbitmq 
yum install rabbitmq-server  -y 1>/dev/null
debug "$1" "$RED Install rabbitmq-server failed $NO_COLOR"
systemctl enable rabbitmq-server.service && 
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack $RABBIT_PASS  1>/dev/null
#Permit configuration, write, and read access for the openstack user:
rabbitmqctl set_permissions openstack ".*" ".*" ".*"  1>/dev/null


}

