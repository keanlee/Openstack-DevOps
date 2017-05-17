#!/bin/bash
#author by keanlee 
#This script need VARIABLE and common.sh

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

mv $(pwd)/admin-openrc  $OPENRC_DIR &&
mv $(pwd)/demo-openrc  $OPENRC_DIR  &&
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
debug "$?" "openstack project create --domain default --description "Service Project" service failed "
#Regular (non-admin) tasks should use an unprivileged project and user. As an example, this guide creates the demo project and user
openstack project create --domain default --description "Demo Project" demo  &&
debug "$?" "openstack project create --domain default --description "Demo Project" demo failed "
#Create the demo user
openstack user create --domain default --password $DEMO_PASS demo   &&
debug "$?"  "openstack user create --domain default --password $DEMO_PASS demo"
#Create the user role
openstack role create user  &&
debug "$?" "openstack role create user failed "
#Add the user role to the demo project and user
openstack role add --project demo --user demo user  &&
debug "$?" "Create a domain, projects, users, and roles failed "
echo $GREEN Finished create domain, project, users and roles on $YELLOW $(hostname) $NO_COLOR 
}

function keystone_main(){
#The OpenStack Identity service provides a single point of integration for managing 
#authentication, authorization, and a catalog of services.
#Please refer:  https://docs.openstack.org/newton/install-guide-rdo/common/get-started-identity.html
#install mariadb and create database for keystone 

database_create keystone $KEYSTONE_DBPASS
yum install openstack-keystone httpd mod_wsgi -y  1>/dev/null

#Edit keystone configuration file 
cp -f ./configuration-files/keystone.conf   /etc/keystone/
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

#execute function to create keystone administrative account 
create_keystone_administrative_account

echo $BLUE Verify operation of the Identity service before installing other services On $YELLOW $(hostname) $NO_COLOR
#Unset the temporary OS_AUTH_URL and OS_PASSWORD environment variable
unset OS_AUTH_URL OS_PASSWORD
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
source  $OPENRC_DIR/admin-openrc 
#Request an authentication token
openstack token issue
debug "$?" "admin-openrc file not work "
echo $GREEN Created openrc file and the admin-openrc can work normally $NO_COLOR 
}
#----------------------------Keystone ------------------
echo $GREEN Beginning install $YELLOW KEYSTONE $NO_COLOR $GREEN ... $NO_COLOR
#Execute below function to install keystone 
yum install openstack-selinux python-openstackclient -y 1>/dev/null 
debug "$?" "$RED Install openstack-selinux python-openstackclient failed $NO_COLOR"
#------Function ------
ntp
rabbitmq_configuration
memcache
keystone_main
echo $GREEN Finished the $YELLOW KEYSTONE $NO_COLOR $GREEN component install $NO_COLOR 
