#!/bin/bash
#author by keanlee 

yum install openstack-selinux python-openstackclient -y 1>/dev/null 
debug "$?" "$RED Install openstack-selinux python-openstackclient failed $NO_COLOR"

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

function keystone(){
#The OpenStack Identity service provides a single point of integration for managing 
#authentication, authorization, and a catalog of services.
#Please refer:  https://docs.openstack.org/newton/install-guide-rdo/common/get-started-identity.html
#install mariadb and create database for keystone 
mysql_configuration
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
#create admin-openrc and demo-openrc file 
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

function create_keystone_administrative_account(){
#Configure the administrative account
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$MGMT_IP:35357/v3
export OS_IDENTITY_API_VERSION=3

#Create a domain, projects, users, and roles
echo $BLUE Beginning create a domain, projects, users, and roles On $YELLOW $(hostname) $NO_COLOR
#This guide uses a service project that contains a unique user for each service 
#that you add to your environment. Create the service project
openstack project create --domain default --description "Service Project" service &&
#Regular (non-admin) tasks should use an unprivileged project and user. As an example, this guide creates the demo project and user
openstack project create --domain default --description "Demo Project" demo  &&
#Create the demo user
openstack user create --domain default --password $DEMO_PASS demo   &&
#Create the user role
openstack role create user  &&
#Add the user role to the demo project and user
openstack role add --project demo --user demo user  &&
debug "$?" "Create a domain, projects, users, and roles failed "
echo $GREEN Finished create domain, project, users and roles on $YELLOW $(hostname) $NO_COLOR 
}
#execute function to create keystone administrative account 
create_keystone_administrative_account

echo $BLUE Verify operation of the Identity service before installing other services On $YELLOW $(hostname) $NO_COLOR
#As the admin user, request an authentication token
openstack --os-auth-url http://$MGMT_IP:35357/v3 --os-project-domain-name default \
--os-user-domain-name default --os-project-name admin --os-username admin \
--os-auth-type password --os-password $ADMIN_PASS  token issue   &&

#As the demo user, request an authentication token
openstack --os-auth-url http://$MGMT:5000/v3 --os-project-domain-name default \
--os-user-domain-name default --os-project-name demo --os-username demo \
--os-auth-type password --os-password $DEMO_PASS token issue   &&
debug "$?" "Verify operation of the Identity service failed "
echo $GREEN Verify operation of the Identity service success $NO_COLOR  &&

#execute this function to create openrc file 
openrc_file_create
#check the admin-openrc file 
source  /root/admin-openrc 
#Request an authentication token
openstack token issue
debug "$?" "admin-openrc file not work "
echo $GREEN Created openrc file and the admin-openrc can work normally $NO_COLOR 
}
#----------------------------Keystone ------------------
echo $GREEN Beginning install $YELLOW KEYSTONE $NO_COLOR $GREEN ... $NO_COLOR
#Execute below function to install keystone 
rabbitmq_configuration
memcache
keystone
echo $GREEN Finished the $YELLOW KEYSTONE $NO_COLOR $GREEN component install $NO_COLOR 
