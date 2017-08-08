#!/bin/bash
#author by keanlee 

function openrc_file_create(){
echo $BLUE create admin-openrc and demo-openrc file $NO_COLOR
    echo >  $(pwd)/admin-openrc
    cat > $(pwd)/admin-openrc <<EOF
#This file create by keanlee's script
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export PS1='[\u@\h \W(keystone_admin_auth)]\$ '
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$MGMT_IP:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

     echo > $(pwd)/demo-openrc
     cat > $(pwd)/demo-openrc <<EOF
#This file create by keanlee's script
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export PS1='[\u@\h \W(keystone_demo_auth)]\$ '
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$MGMT_IP:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

mv $(pwd)/admin-openrc  $OPENRC_DIR &&
mv $(pwd)/demo-openrc  $OPENRC_DIR  &&
echo $GREEN openrc file created and location at ${YELLOW}$OPENRC_DIR${NO_COLOR}${GREEN} directory $NO_COLOR
}

function create_keystone_administrative_account(){
echo $BLUE Configure the administrative account ... $NO_COLOR
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://${MGMT_IP}:35357/v3
export OS_IDENTITY_API_VERSION=3

echo $BLUE Beginning create a domain, projects, users, and roles On $YELLOW $(hostname) $NO_COLOR
#This guide uses a service project that contains a unique user for each service 
#that you add to your environment. Create the service project
openstack project create --domain default --description "Service Project" service &&
    debug "$?" "openstack project create --domain default --description \"Service Project\" service failed "

#Regular (non-admin) tasks should use an unprivileged project and user. As an example, this guide creates the demo project and user
openstack project create --domain default --description "Demo Project" demo  &&
    debug "$?" "openstack project create --domain default --description \"Demo Project\" demo failed "

echo $BLUE Create the demo user ... $NO_COLOR
openstack user create --domain default --password ${DEMO_PASS} demo   &&
    debug "$?"  "openstack user create --domain default --password ${DEMO_PASS} demo failed "

echo $BLUE Create the user role  $NO_COLOR
openstack role create user  &&
    debug "$?" "openstack role create user failed "

echo $BLUE Add the user role to the demo project and user $NO_COLOR
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
echo $BLUE Install openstack-keystone httpd mod_wsgi ... $NO_COLOR
yum install openstack-keystone httpd mod_wsgi -y  1>/dev/null
   debug "$?" "Install openstack-keystone httpd mod_wsgi failed "

#Edit keystone configuration file 
cp -f ./etc/controller/keystone.conf   /etc/keystone/
sed -i "s/controller/$MGMT_IP/g"  /etc/keystone/keystone.conf
sed -i "s/KEYSTONE_DBPASS/$KEYSTONE_DBPASS/g" /etc/keystone/keystone.conf

#Since copy the conf to target need to chown 
chown -R keystone:keystone /etc/keystone/keystone.conf

if [[ $(get_database_size keystone ${KEYSTONE_DBPASS} | awk '{print $6}') != "NULL" ]];then 
    echo $YELLOW Skip populate keystone database, since it\'s has populated   $NO_COLOR
else
    echo $BLUE Populate the Identity service database ... $NO_COLOR
    su -s /bin/sh -c "keystone-manage db_sync" keystone
    get_database_size keystone ${KEYSTONE_DBPASS}
fi

echo $BLUE Initialize Fernet key repositories ... $NO_COLOR
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

echo $BLUE Bootstrap the Identity service ... $NO_COLOR
keystone-manage bootstrap --bootstrap-password ${ADMIN_PASS} \
--bootstrap-admin-url http://${MGMT_IP}:35357/v3/  \
--bootstrap-internal-url http://${MGMT_IP}:35357/v3/  \
--bootstrap-public-url http://${MGMT_IP}:5000/v3/   \
--bootstrap-region-id RegionOne

echo $BLUE Configure the Apache HTTP server ... $NO_COLOR
sed -i "/ServerName www.example.com:80/a\ServerName $MGMT_IP" /etc/httpd/conf/httpd.conf  1>/dev/null
echo $BLUE Create a link to the /usr/share/keystone/wsgi-keystone.conf file: $NO_COLOR

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/     1>/dev/null

systemctl enable httpd.service     1>/dev/null 2>&1
systemctl start httpd.service

#execute function to create keystone administrative account 
create_keystone_administrative_account

echo $BLUE Verify operation of the Identity service before installing other services On $YELLOW $(hostname) $NO_COLOR
#Unset the temporary OS_AUTH_URL and OS_PASSWORD environment variable
unset OS_AUTH_URL OS_PASSWORD

echo $BLUE As the admin user, request an authentication token $NO_COLOR
openstack --os-auth-url http://${MGMT_IP}:35357/v3 --os-project-domain-name default \
--os-user-domain-name default --os-project-name admin --os-username admin \
--os-auth-type password --os-password ${ADMIN_PASS}  token issue   &&
    debug "$?"  "As the admin user, request an authentication token Failed "


echo $BLUE As the demo user, request an authentication token  $NO_COLOR
openstack --os-auth-url http://${MGMT_IP}:5000/v3 --os-project-domain-name default \
--os-user-domain-name default --os-project-name demo --os-username demo \
--os-auth-type password --os-password ${DEMO_PASS} token issue   &&
echo $GREEN Verify operation of the Identity service success $NO_COLOR  &&

#execute this function to create openrc file 
openrc_file_create

echo $BLUE Check the admin-openrc file which location at ${YELLOW}$OPENRC_DIR${NO_COLOR}${BLUE} whether or not work $NO_COLOR 
source  $OPENRC_DIR/admin-openrc 

#Request an authentication token
openstack token issue
    debug "$?" "The admin-openrc file which location at $OPENRC_DIR can not be work "
echo $GREEN Created openrc file and the admin-openrc can be work normally $NO_COLOR 
}

#----------------------------Keystone ------------------
#Execute below function to install keystone 

cat 2>&1 <<__EOF__
$MAGENTA================================================================
            Begin to delpoy Keystone
================================================================
$NO_COLOR
__EOF__

 
keystone_main

cat 2>&1 <<__EOF__
$GREEN================================================================================================================
  Congratulation you finished the ${YELLOW}KEYSTONE (include httpd mod_wsgi)${NO_COLOR}${GREEN} component 
install.For more info about keystone you can refer /usr/share/doc/openstack-keystone-10.0.1/README.rst file      
================================================================================================================
$NO_COLOR
__EOF__


