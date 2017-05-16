#!/bin/bash 
#This script can check the Openstack stauts 
function mariadb_check(){
#check the database and users whether or not create 
mysql -u root -p$MARIADB_PASSWORD -e "show databases ;" |egrep "glance|keystone|neutron|nova|nova_api"
mysql -u root -p$MARIADB_PASSWORD -e "select user,host from mysql.user ;" |egrep "cinder|glance|keystone|neutron|nova"

}
#rabbitmq check 
#check rabbitmq plugin lists 
rabbitmq-plugins list

#check the porot whether or not listen 
netstat -lntp | grep <ports>
