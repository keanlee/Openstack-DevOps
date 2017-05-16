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
#RABBIT_P 
#Except Horizone and keystone ,each component need connect to Rabbitmq 
yum install rabbitmq-server  -y 1>/dev/null
debug "$1" "$RED Install rabbitmq-server failed $NO_COLOR"
systemctl enable rabbitmq-server.service 1>/dev/null && 
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack $RABBIT_PASS  1>/dev/null
#Permit configuration, write, and read access for the openstack user:
rabbitmqctl set_permissions openstack ".*" ".*" ".*"  1>/dev/null
#rabbitmq-plugins list
#enable rabbitmq_management boot after the os boot 
#Use rabbitmq-web 
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server.service
}

function memcache(){
#install and configuration memecache 
#Need variable MGMT_IP
#The Identity service authentication mechanism for services uses Memcached to cache tokens. 
#The memcached service typically runs on the controller node. 
#For production deployments, we recommend enabling a combination of firewalling, authentication, and encryption to secure it.
yum install memcached python-memcached -y 1>/dev/null
sed -i "s/127.0.0.1/$MGMT_IP/g" /etc/sysconfig/memcached
systemctl enable memcached.service && 1>/dev/null
systemctl start memcached.service
}

function database_create(){
#create database and user in mariadb for openstack component
#$1 is the database name (comonent name and usename) 
#$2 is password of database

mysql -uroot -p$MARIADB_PASSWORD -e "create database $1 character set utf8;grant all privileges on $1.* to $1@localhost \
identified by '$2';flush privileges;"  
debug "$?" "Create database $1 Failed "
}

function keystone(){
#The OpenStack Identity service provides a single point of integration for managing 
#authentication, authorization, and a catalog of services.
#Please refer:  https://docs.openstack.org/newton/install-guide-rdo/common/get-started-identity.html
#create database for keystone 
database_create keystone $KEYSTONE_DBPASS
yum install openstack-keystone httpd mod_wsgi -y  1>/dev/null

#Edit keystone configuration file 
cp -f ./configuration-file/keystone.conf   /etc/keystone/
sed -i "s/controller/$MGMT_IP/g"  /etc/keystone/keystone.conf
sed -i "s/KEYSTONE_DBPASS/$KEYSTONE_DBPASS/g" /etc/keystone/keystone.conf
#Populate the Identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone
#Initialize Fernet key repositories
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
#Bootstrap the Identity service
  keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$MGMT_IP:35357/v3/ \
  --bootstrap-internal-url http://$MGMT_IP:35357/v3/ \
  --bootstrap-public-url http://$MGMT_IP:5000/v3/ \
  --bootstrap-region-id RegionOne

chown -R keystone.keystone /etc/keystone/credential-keys
chown -R keystone.keystone /etc/keystone/fernet-keys

#Configure the Apache HTTP server
sed -i "/ServerName www.example.com:80/a\ServerName $MGMT_IP" /etc/httpd/conf/httpd.conf  1>/dev/null
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/     1>/dev/null
systemctl enable httpd.service     1>/dev/null
systemctl start httpd.service
function openrc_file_create(){
    echo >  $(pwd)/admin-openrc
    cat > $(pwd)/admin-openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$MGMT_IP:10006/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

     echo > $(pwd)/demo-openrc
     cat > $(pwd)/demo-openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$MGMT_IP:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

mv $(pwd)/admin-openrc  /root &&
mv $(pwd)/demo-openrc  /root  &&
echo $GREEN openrc file created and location at /root directory $NO_COLOR

}

}



