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

cd $(cd $(dirname $0); pwd)

#Set the Env...
source ./common.sh ha
yum_repos ha
initialize_env
source ./firewall.sh

#------------------------------Galera ----------------------------------------------------------------
function Galera(){

if [[ -e ~/.ssh/id_rsa.pub ]];then
    echo $BLUE the id_rsa.pub file has already exist $NO_COLOR
else
    echo $BLUE Generating public/private rsa key pair $NO_COLOR
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa  1>/dev/null
    #-N "" tells it to use an empty passphrase (the same as two of the enters in an interactive script)
    #-f my.key tells it to store the key into my.key (change as you see fit).
fi

which sshpass 1>/dev/null 2>&1 || rpm -ivh ../lib/sshpass* 1>/dev/null 2>&1
echo $BLUE copy public key to controller hosts:  $NO_COLOR
if [[ -e  ~/.ssh/known_hosts ]];then
    echo $BLUE know_hosts file exist $NO_COLOR
else
    touch ~/.ssh/known_hosts
fi

for ips in ${CONTROLLER_IP[*]};do
        if [[ $(cat ~/.ssh/known_hosts | grep $ips | wc -l) -ge 2 ]];then        
            continue
        else
            ssh-keyscan $ips >> ~/.ssh/known_hosts ;
        fi
done

for ips in ${CONTROLLER_IP[*]};
   do sshpass -p ${PASSWORD_EACH_NODE} ssh-copy-id -i ~/.ssh/id_rsa.pub  $ips;
done

#add hostname with ip addr to hosts file 
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

    cp -f ../etc/HA/galera.cnf /etc/my.cnf.d/
    sed -i "s/this-host-name/$(hostname)/g" /etc/my.cnf.d/galera.cnf
    sed -i "s/this-host-ip/$MGMT_IP/g"  /etc/my.cnf.d/galera.cnf
    sed -i "s/cluster-nodes/${CONTROLLER_HOSTNAME[0]},${CONTROLLER_HOSTNAME[1]},${CONTROLLER_HOSTNAME[2]}/g"  /etc/my.cnf.d/galera.cnf

#service mysql start --wsrep-new-cluster
#systemctl start mariadb --wsrep-new-cluster
    echo $BLUE start mariadb galera cluster ...$NO_COLOR
    #systemctl start mariadb --wsrep-new-cluster --user=mysql 1>/dev/null
    /usr/libexec/mysqld --wsrep-new-cluster --user=mysql &  1>/dev/null 2>&1  
        debug "$?" "start galera cluster on $(hostname) failed "
    sleep 2
    echo $GREEN Finshed Galera Install On ${YELLOW}$(hostname) $NO_COLOR
else 
    cp -f ../etc/HA/galera.cnf /etc/my.cnf.d/
    sed -i "s/this-host-name/$(hostname)/g" /etc/my.cnf.d/galera.cnf
    sed -i "s/this-host-ip/$MGMT_IP/g"  /etc/my.cnf.d/galera.cnf
    sed -i "s/cluster-nodes/${CONTROLLER_HOSTNAME[0]},${CONTROLLER_HOSTNAME[1]},${CONTROLLER_HOSTNAME[2]}/g"  /etc/my.cnf.d/galera.cnf
    #for each node 
    systemctl enable mariadb  1>/dev/null 2>&1
    sed -i '/Group=mysql/a\LimitNOFILE=65535' /usr/lib/systemd/system/mariadb.service
    systemctl daemon-reload
    echo $BLUE start mariadb ...$NO_COLOR
    systemctl start mariadb 
        debug "$?"  "Start mariadb failed on $(hostname)"
    echo $GREEN Finshed Galera Install On ${YELLOW}$(hostname) $NO_COLOR
fi  

#check status after install and configure it 
#mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_%';"
#mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
}


function load_balancing(){
# load-balancing client
#Generally, we use round-robin to distribute load amongst instances of active/active services. 
#Alternatively, Galera uses stick-table options to ensure that incoming connection to virtual IP (VIP) are 
#directed to only one of the available back ends. This helps avoid lock contention and prevent deadlocks, although 
#Galera can run active/active. Used in combination with 
#the httpchk option, this ensure only nodes that are in sync with their peers are allowed to handle requests.

yum install xinetd  -y 1>/dev/null 
echo $BLUE Install haproxy keepalived ...$NO_COLOR
yum install haproxy keepalived  -y 1>/dev/null
echo $BLUE Config the haproxy for controller $NO_COLOR
cp -f ../etc/HA/haproxy.cfg  /etc/haproxy/
sed -i "s/<Virtual IP>/${CONTROLLER_VIP}/g"  /etc/haproxy/haproxy.cfg

sed -i "s/controller1-hostname/${CONTROLLER_HOSTNAME[0]}/g"  /etc/haproxy/haproxy.cfg
sed -i "s/controller2-hostname/${CONTROLLER_HOSTNAME[1]}/g"  /etc/haproxy/haproxy.cfg
sed -i "s/controller3-hostname/${CONTROLLER_HOSTNAME[2]}/g"  /etc/haproxy/haproxy.cfg

sed -i "s/CONTROLLER1_IP/${CONTROLLER_IP[0]}/g" /etc/haproxy/haproxy.cfg
sed -i "s/CONTROLLER2_IP/${CONTROLLER_IP[1]}/g" /etc/haproxy/haproxy.cfg
sed -i "s/CONTROLLER3_IP/${CONTROLLER_IP[2]}/g" /etc/haproxy/haproxy.cfg


#Configure the kernel parameter to allow non-local IP binding. 
#This allows running HAProxy instances to bind to a VIP for failover. 
echo $BLUE Config the keepalived for controller $NO_COLOR
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sysctl -p  1>/dev/null
cp -f ../etc/HA/keepalived.conf /etc/keepalived/
cp -f ../etc/HA/haproxy-status-check.sh   /etc/keepalived/
chmod 777 /etc/keepalived/haproxy-status-check.sh
if [[ $MGMT_IP = ${CONTROLLER_IP[0]} ]];then 
    sed -i "s/ROLEs/MASTER/g"   /etc/keepalived/keepalived.conf
    sed -i "s/priority_nums/${PRIORITY_NUMS[0]}/g" /etc/keepalived/keepalived.conf 
    sed -i "s/controller_peer1/${CONTROLLER_IP[1]}/g" /etc/keepalived/keepalived.conf
    sed -i "s/controller_peer2/${CONTROLLER_IP[2]}/g" /etc/keepalived/keepalived.conf
elif [[ $MGMT_IP = ${CONTROLLER_IP[1]} ]];then
    sed -i "s/ROLEs/BACKUP/g"   /etc/keepalived/keepalived.conf
    sed -i "s/priority_nums/${PRIORITY_NUMS[1]}/g" /etc/keepalived/keepalived.conf
    sed -i "s/controller_peer1/${CONTROLLER_IP[0]}/g" /etc/keepalived/keepalived.conf
    sed -i "s/controller_peer2/${CONTROLLER_IP[2]}/g" /etc/keepalived/keepalived.conf
elif [[ $MGMT_IP = ${CONTROLLER_IP[2]} ]];then 
   sed -i "s/ROLEs/BACKUP/g"   /etc/keepalived/keepalived.conf
   sed -i "s/priority_nums/${PRIORITY_NUMS[2]}/g" /etc/keepalived/keepalived.conf
   sed -i "s/controller_peer1/${CONTROLLER_IP[0]}/g" /etc/keepalived/keepalived.conf
   sed -i "s/controller_peer2/${CONTROLLER_IP[1]}/g" /etc/keepalived/keepalived.conf
else
   continue 
fi

sed -i "s/VIP_NETWORK_DEVICE/${MGMT_IP_DEVICE}/g"  /etc/keepalived/keepalived.conf
sed -i "s/ROUTER_ID/${ROUTER_ID}/g"  /etc/keepalived/keepalived.conf 
sed -i "s/CONTROLLER_VIP/${CONTROLLER_VIP}/g"  /etc/keepalived/keepalived.conf 
sed -i "s/LOCAL_IP/${MGMT_IP}/g" /etc/keepalived/keepalived.conf 
#vrrp_script chk_http_port  ADD this next time 
echo $BLUE Start the keepalived.service ...  $NO_COLOR
systemctl enable haproxy  1>/dev/null 2>&1
systemctl enable keepalived.service 1>/dev/null 2>&1 &&
systemctl start keepalived.service  &&
    debug "$?" "Start keepalived.service failed "
sleep 3
HAPROXY_STATUS=$(systemctl status haproxy | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
if [[ $HAPROXY_STATUS = "inactive" ]];then 
    echo $BLUE The ha-porxy Status: ${RED}inactive $NO_COLOR
elif [[ $HAPROXY_STATUS = "active" ]];then
    echo $BLUE The ha-porxy Status: ${GREEN}active $NO_COLOR
else
    echo $BLUE The ha-porxy Status: ${YELLOW}${{HAPROXY_STATUS} $NO_COLOR
fi
}


function rabbitmq_ha(){

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
       Galera
       load_balancing
       ;;
    *)
        debug "1" " ${YELLOW}$1${RED} is unsupport parameter !!!"
esac 





