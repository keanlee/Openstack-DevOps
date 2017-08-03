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

CONTROLLER_IP=(
192.168.1.11
192.168.1.5
192.168.1.10
)
CONTROLLER_HOSTNAME=(
host-192-168-1-11
host-192-168-1-5
host-192-168-1-10
)
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



function Galera(){

#yum repos setpup 
#修改 /etc/hostname
echo  "${CONTROLLER_IP[0]}   ${CONTROLLER_HOSTNAME[0]}" >>/etc/hosts
echo  "${CONTROLLER_IP[1]}   ${CONTROLLER_HOSTNAME[1]}" >>/etc/hosts
echo  "${CONTROLLER_IP[2]}   ${CONTROLLER_HOSTNAME[2]}" >>/etc/hosts
iptables -F
systemctl stop firewalld	
setenforce 0
echo $BLUE Install  mariadb mariadb-galera-server mariadb-galera-common galera rsync $NO_COLOR
yum install -y  mariadb mariadb-galera-server mariadb-galera-common galera rsync  1>/dev/null
    debug "$?" "install galera mariadb fialed on $(hostname)"
if [[ $(hostname) = ${CONTROLLER_HOSTNAME[0]} ]];then 
    sed -i '/Group=mysql/a\LimitNOFILE=65535' /usr/lib/systemd/system/mariadb.service
    systemctl daemon-reload
    systemctl enable mariadb
    systemctl start mariadb
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

#将此文件复制到node5、node6，注意要把 wsrep_node_name和 wsrep_node_address改成相应节点的 hostname和ip
#启动 MariaDB Galera Cluster 服务
#service mysql start --wsrep-new-cluster
#systemctl start mariadb --wsrep-new-cluster
    /usr/libexec/mysqld --wsrep-new-cluster --user=root &
    echo $GREEN Finshed Galera Install On $(hostname) $NO_COLOR
else 
    cp -f ../etc/ha_proxy/galera.cnf /etc/my.cnf.d/
    sed -i "s/this-host-name/$(hostname)/g" /etc/my.cnf.d/galera.cnf
    sed -i "s/this-host-ip/$MGMT_IP/g"  /etc/my.cnf.d/galera.cnf
    sed -i "s/cluster-nodes/${CONTROLLER_HOSTNAME[0]},${CONTROLLER_HOSTNAME[1]},${CONTROLLER_HOSTNAME[2]}/g"  /etc/my.cnf.d/galera.cnf
    #for each node 
    systemctl enable mariadb
    systemctl start mariadb 
    echo $GREEN Finshed Galera Install On $(hostname) $NO_COLOR
fi  
#查看集群状态

#check status after install and configure it 
#mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_%';"
#mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
}

