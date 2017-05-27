#!/bin/bash 
#This script can check the Openstack stauts 
function mariadb_check(){
#check the database and users whether or not create 
mysql -uroot -padmin -e "show databases ;" |egrep "glance|keystone|neutron|nova|nova_api"
mysql -uroot -padmin -e "select user,host from mysql.user ;" |egrep "cinder|glance|keystone|neutron|nova"

}
#rabbitmq check 
#check rabbitmq plugin lists 
mariadb_check

rabbitmq-plugins list


source /home/admin-openrc
nova service-list

neutron agent-list

cinder service-list

#check the porot whether or not listen 
#netstat -lntp | grep <ports>
