#!/bin/bash 
#This script will prepare the env for install openstack 
#Include function ntp mysql rabbitmq memcache  

# ansi colors for formatting heredoc
ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"
MAGENTA="$ESC[0;35m"
YELLOW="$ESC[0;33m"
BLUE="$ESC[0;34m"
WHITE="$ESC[0;37m"
#PURPLE="$ESC[0;35m"
CYAN="$ESC[0;36m"

source ./bin/VARIABLE 

debug(){
if [[ $1 -ne 0 ]]; then 
echo $RED $2 $NO_COLOR
exit 1
fi
}


#----------------disable selinux-------------------------
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo $GREEN Disable the selinux by config file. The current selinux Status:$NO_COLOR $YELLOW $(getenforce) $NO_COLOR

function ntp(){
cat 1>&2 <<__EOF__
$MAGENTA==========================================================
            Begin to delpoy ntp
==========================================================
$NO_COLOR
__EOF__

yum install ntp -y  1>/dev/null
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate $NTP_SERVER_IP 1>/dev/null
hwclock --systohc
sed -i "/server 0.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "/server 1.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "/server 2.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "/server 3.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "21 i server $NTP_SERVER_IP iburst " /etc/ntp.conf
systemctl enable ntpd.service 1>/dev/null 2>&1 && 
systemctl start ntpd.service
}

function mysql_configuration(){
cat 1>&2 <<__EOF__
$MAGENTA==========================================================
            Begin to delpoy Mariadb
==========================================================
$NO_COLOR
__EOF__

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
systemctl enable mariadb.service 1>/dev/null 2>&1 && 
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

function database_create(){
#create database and user in mariadb for openstack component
#$1 is the database name (comonent name and usename) 
#$2 is password of database

echo $BLUE      Create $1 database in mariadb  $NO_COLOR
local USER=$1
if [[ $1 = nova_api ]];then
USER=nova
fi 

mysql -uroot -p$MARIADB_PASSWORD -e "CREATE DATABASE $1;GRANT ALL PRIVILEGES ON $1.* TO '$USER'@'localhost' \
IDENTIFIED BY '$2';GRANT ALL PRIVILEGES ON $1.* TO '$USER'@'%'  IDENTIFIED BY '$2';flush privileges;"  
debug "$?" "Create database $1 Failed "
}

function rabbitmq_configuration(){
cat 1>&2 <<__EOF__
$MAGENTA==========================================================
            Begin to delpoy RabbitMQ 
==========================================================
$NO_COLOR
__EOF__

#RABBIT_P 
#Except Horizone and keystone ,each component need connect to Rabbitmq 
echo $BLUE Install rabbitmq-server ... $NO_COLOR
yum install rabbitmq-server  -y 1>/dev/null
debug "$1" "$RED Install rabbitmq-server failed $NO_COLOR"
systemctl enable rabbitmq-server.service 1>/dev/null 2>&1 && 
systemctl start rabbitmq-server.service
debug "$?" "systemctl start rabbitmq-server.service Faild, Did you edit the /etc/hosts ? "

rabbitmqctl add_user openstack $RABBIT_PASS  1>/dev/null
echo $BLUE Permit configuration, write, and read access for the openstack user ...$NO_COLOR
rabbitmqctl set_permissions openstack ".*" ".*" ".*"  1>/dev/null

#rabbitmq-plugins list
#enable rabbitmq_management boot after the os boot 
#Use rabbitmq-web 
rabbitmq-plugins enable rabbitmq_management 1>/dev/null 2>&1
systemctl restart rabbitmq-server.service &&
debug "$?" "Restart rabbitmq-server.service fail after enable rabbitmq_management "
echo $GREEN You can browse rabbitmq web via 15672 port $NO_COLOR
}

function memcache(){
#install and configuration memecache 
#Need variable MGMT_IP
#The Identity service authentication mechanism for services uses Memcached to cache tokens. 
#The memcached service typically runs on the controller node. 
#For production deployments, we recommend enabling a combination of firewalling, authentication, and encryption to secure it.
yum install memcached python-memcached -y 1>/dev/null
sed -i "s/127.0.0.1/$MGMT_IP/g" /etc/sysconfig/memcached
systemctl enable memcached.service   1>/dev/null 2>&1 &&
systemctl start memcached.service
}


function create_service_credentials(){
#This function need parameter :
#$1 is the service password 
#$2 is the service name ,example nova glance neutron cinder etc. 
#
cat 1>&2 <<__EOF__
$MAGENTA==========================================================
          Create $2 service credentials 
==========================================================
$NO_COLOR
__EOF__

echo $BLUE To create the service credentials, complete these steps: $NO_COLOR 

source $OPENRC_DIR/admin-openrc
echo $BLUE create the service credentials: $NO_COLOR
echo $BLUE Create the $2  user  $NO_COLOR
openstack user create --domain default --password $1  $2  &&

echo $BLUE Add the admin role to the $2 user and service project $NO_COLOR
openstack role add --project service --user $2 admin

echo $BLUE Create the $2 service entity $NO_COLOR
case $2 in
glance)
local SERVICE=Image
local SERVICE1=image
local PORTS=9292
;;
nova)
local SERVICE=Compute
local SERVICE1=compute
local PORTS=8774
;;
neutron)
local SERVICE=Networking
local SERVICE1=network 
local PORTS=9696
;;
cinder)
local SERVICE=Block Storage
local PORTS=8776
local SERVICE1=volume
;;
*)
debug "1" "The second parameter is the service name: nova glance neutron cinder etc,your $2 is unkown "
;;
esac 
sleep 2
openstack service create --name $2 --description "OpenStack ${SERVICE}" ${SERVICE1}
debug "$?" "openstack service $2 create failed "

if [[ $2 = cinder ]];then 
openstack service create --name cinderv2 --description "OpenStack ${SERVICE}" volumev2
debug "$?" "openstack service volumev2 create failed "
else 
continue 
fi

echo $BLUE Create the ${YELLOW}$SERVICE${NO_COLOR}${BLUE} service API endpoints $NO_COLOR

if [[ $2 = nova ]];then 
openstack endpoint create --region RegionOne ${SERVICE1} public http://$MGMT_IP:${PORTS}/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne ${SERVICE1} internal http://$MGMT_IP:${PORTS}/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne ${SERVICE1} admin http://$MGMT_IP:${PORTS}/v2.1/%\(tenant_id\)s
debug "$?" "openstack endpoint create $2 failed "

elif [[ $2 = cinder ]];then
openstack endpoint create --region RegionOne ${SERVICE1} public http://$MGMT_IP:${PORTS}/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne ${SERVICE1} internal http://$MGMT_IP:${PORTS}/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne ${SERVICE1} admin http://$MGMT_IP:${PORTS}/v1/%\(tenant_id\)s
debug "$?" "openstack endpoint create $2 failed "

openstack endpoint create --region RegionOne volumev2 public http://$MGMT_IP:${PORTS}/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://$MGMT_IP:${PORTS}/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://$MGMT_IP:${PORTS}/v2/%\(tenant_id\)s
debug "$?" "openstack endpoint create $2 failed "

else 
openstack endpoint create --region RegionOne ${SERVICE1} public http://$MGMT_IP:${PORTS}
openstack endpoint create --region RegionOne ${SERVICE1} internal http://$MGMT_IP:${PORTS}
openstack endpoint create --region RegionOne ${SERVICE1} admin http://$MGMT_IP:${PORTS}
debug "$?" "openstack endpoint create $2 failed "
fi 
echo $GREEN openstack $2 endpoint create success $NO_COLOR 
}
