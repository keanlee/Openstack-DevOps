#!/bin/bash
#write by keanlee in June of 2017
#https://docs.openstack.org/ha-guide/intro-ha.html#stateless-versus-stateful-services

#refer docs: https://mariadb.com/kb/en/mariadb/yum/#installing-mariadb-galera-cluster-with-yum
#http://www.linuxidc.com/Linux/2015-07/119512.htm

#steps 
#memcache no ha 
#http://freeloda.blog.51cto.com/2033581/1280962  for keepalived 

#for selinux open
#semanage port -a -t mysqld_port_t -p tcp 3306

#semanage permissive -a mysqld_t

function __main__(){
cd $(cd $(dirname $0); pwd)

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

function debug(){
if [[ $1 -ne 0 ]]; then
    echo $RED ERROR:  $2 $NO_COLOR
    exit 1
fi
}
source ./VARIABLE
source ../HOSTS

#---------------------------initialize env ------------------------------------
function initialize_env(){
#----------------disable selinux-------------------------
cat 2>&1 <<__EOF__
$MAGENTA==========================================================
            Begin to initialize env ...
==========================================================
$NO_COLOR
__EOF__

if [[ $(cat /etc/selinux/config | sed -n '7p' | awk -F "=" '{print $2}') = "enforcing" ]];then
     echo $BLUE Disable selinux $NO_COLOR
     sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
     echo $GREEN Disable the selinux by config file $NO_COLOR
fi

if [[ $(getenforce) = "Enforcing" ]];then
    setenforce 0
    echo $GREEN The current selinux Status:$NO_COLOR $YELLOW $(getenforce) $NO_COLOR 
fi

systemctl status NetworkManager 1>/dev/null 2>&1
if [[ $? = 0 ]];then
    echo $BLUE Uninstall NetworkManager $NO_COLOR
    systemctl stop NetworkManager 1>/dev/null 2>&1
    yum erase NetworkManager  -y 1>/dev/null 2>&1
fi

which firewall-cmd  1>/dev/null 2>&1 &&
echo $BLUE Uninstall firewalld $NO_COLOR
yum erase firewalld* -y 1>/dev/null 2>&1
}

#-----------------------------yum repos configuration ---------------------------
function yum_repos(){
if [[ ! -d /etc/yum.repos.d/bak/ ]];then
    mkdir /etc/yum.repos.d/bak/
fi
mv /etc/yum.repos.d/* /etc/yum.repos.d/bak/  1>/dev/null 2>&1
cp -f ../repos/* /etc/yum.repos.d/ 2>/dev/null
yum clean all 1>/dev/null 2>1&
echo $GREEN yum repos configuration done $NO_COLOR
}
yum_repos
}


#------------------------------Galera ----------------------------------------------------------------
function Galera(){
#this function can deploy three galera node 
echo  "${CONTROLLER_IP[0]}   ${CONTROLLER_HOSTNAME[0]}" >>/etc/hosts
echo  "${CONTROLLER_IP[1]}   ${CONTROLLER_HOSTNAME[1]}" >>/etc/hosts
echo  "${CONTROLLER_IP[2]}   ${CONTROLLER_HOSTNAME[2]}" >>/etc/hosts

echo $BLUE Install  mariadb mariadb-galera-server mariadb-galera-common galera rsync ...$NO_COLOR
yum install -y  mariadb mariadb-galera-server mariadb-galera-common galera rsync  1>/dev/null
    debug "$?" "install galera  fialed on $(hostname)"

if [[ $(hostname) = ${CONTROLLER_HOSTNAME[0]} ]];then 
    sed -i '/Group=mysql/a\LimitNOFILE=65535' /usr/lib/systemd/system/mariadb.service
    systemctl daemon-reload
    systemctl enable mariadb  1>/dev/null 2>&1
    #chown mysql:mysql /var/lib/mysql/grastate.dat
    #chown mysql:mysql  /var/lib/mysql/galera.cache
    systemctl start mariadb
        debug "$?" "Start mairadb failed on $(hostname)"
    echo $BLUE Set admin password for galera mariadb... $NO_COLOR

    mysql_secure_installation 1>/dev/null 2>&1 <<EOF

y
$GALERA_PASSWORD
$GALERA_PASSWORD
y
y
y
y
EOF
    debug "$?" "GALERA admin password configuration failed"
    systemctl stop mariadb

    cp -f ../etc/ha_proxy/galera.cnf /etc/my.cnf.d/
    sed -i "s/this-host-name/$(hostname)/g" /etc/my.cnf.d/galera.cnf
    sed -i "s/this-host-ip/$MGMT_IP/g"  /etc/my.cnf.d/galera.cnf
    sed -i "s/cluster-nodes/${CONTROLLER_HOSTNAME[0]},${CONTROLLER_HOSTNAME[1]},${CONTROLLER_HOSTNAME[2]}/g"  /etc/my.cnf.d/galera.cnf

#start  MariaDB Galera Cluster ...
#service mysql start --wsrep-new-cluster
#systemctl start mariadb --wsrep-new-cluster
    /usr/libexec/mysqld --wsrep-new-cluster --user=mysql & 1>/dev/null 
        debug "$?" "start galera cluster on $(hostname) failed "
    sleep 2
    echo $GREEN Finshed Galera Install On $(hostname) $NO_COLOR
else 
    cp -f ../etc/ha_proxy/galera.cnf /etc/my.cnf.d/
    sed -i "s/this-host-name/$(hostname)/g" /etc/my.cnf.d/galera.cnf
    sed -i "s/this-host-ip/$MGMT_IP/g"  /etc/my.cnf.d/galera.cnf
    sed -i "s/cluster-nodes/${CONTROLLER_HOSTNAME[0]},${CONTROLLER_HOSTNAME[1]},${CONTROLLER_HOSTNAME[2]}/g"  /etc/my.cnf.d/galera.cnf
    #for each node 
    systemctl enable mariadb  1>/dev/null 2>&1
    sed -i '/Group=mysql/a\LimitNOFILE=65535' /usr/lib/systemd/system/mariadb.service
    systemctl daemon-reload
    systemctl start mariadb 
        debug "$?"  "Start mariadb failed on $(hostname)"
    echo $GREEN Finshed Galera Install On $(hostname) $NO_COLOR
fi  

#check status after install and configure it 
#mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_%';"
#mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
}






function load_balancing(){
yum install xinetd
# load-balancing client
yum install haproxy

yum install keepalived 
}

function rabbitmq_ha(){
yum install rabbitmq-server 
scp /var/lib/rabbitmq/.erlang.cookie root@NODE:/var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie

echo $BLUE Verify that the nodes are running:$NO_COLOR
rabbitmqctl cluster_status

#Run the following commands on each node except the first one:
rabbitmqctl stop_app
rabbitmqctl join_cluster --ram rabbit@rabbit1
rabbitmqctl start_app

#check the status again ...
rabbitmqctl cluster_status 

#If the cluster is working, you can create usernames and passwords for the queues.
rabbitmqctl add_user openstack $RABBIT_PASS  1>/dev/null
echo $BLUE Permit configuration, write, and read access for the openstack user ...$NO_COLOR
rabbitmqctl set_permissions openstack ".*" ".*" ".*"  1>/dev/null

#To ensure that all queues except those with auto-generated names are mirrored across all running nodes,
# set the ha-mode policy key to all by running the following command on one of the nodes:
rabbitmqctl set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}'


#for openstack services to use Rabbit HA queues 
#edit it to conf file 
transport_url = rabbit://RABBIT_USER:RABBIT_PASS@rabbit1:5672,
RABBIT_USER:RABBIT_PASS@rabbit2:5672,RABBIT_USER:RABBIT_PASS@rabbit3:5672
#Replace RABBIT_USER with RabbitMQ username and RABBIT_PASS with password for respective RabbitMQ host. 

#Retry connecting with RabbitMQ:
rabbit_retry_interval=1

#How long to back-off for between retries when connecting to RabbitMQ:
rabbit_retry_backoff=2

#Maximum retries with trying to connect to RabbitMQ (infinite by default):
rabbit_max_retries=0

#Use durable queues in RabbitMQ:
rabbit_durable_queues=true

#Use HA queues in RabbitMQ (x-ha-policy: all):
rabbit_ha_queues=true


#If you change the configuration from an old set-up that did not use HA queues, restart the service:
# rabbitmqctl stop_app
# rabbitmqctl reset
# rabbitmqctl start_app

}


case $1 in 
    galera)
       __main__
       initialize_env
       iptables -F
       Galera
       ;;
    *)
        debug "1" "unsupport parameter !!!"
esac 





