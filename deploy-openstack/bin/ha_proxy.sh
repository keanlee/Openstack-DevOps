#!/bin/bash

#refer docs: https://mariadb.com/kb/en/mariadb/yum/#installing-mariadb-galera-cluster-with-yum
#http://www.linuxidc.com/Linux/2015-07/119512.htm

function Galera(){
yum install -y  mariadb mariadb-galera-server mariadb-galera-common galera rsync

sed -i '/Group=mysql/a\LimitNOFILE=65535' /usr/lib/systemd/system/mariadb.service
systemctl daemon-reload

setenforce 0
systemctl enable mariadb
systemctl start mariadb
GALERA_PASSWORD=GALERA_PASSWORDadmin

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

systemctl stop mariadb

cp -f ./etc/ha_proxy/galera.cnf /etc/my.cnf.d/
sed -i "s/this-host-name/$(hostname)/g" /etc/my.cnf.d/galera.cnf
sed -i "s/this-host-ip/$MGMT_IP/g"  /etc/my.cnf.d/galera.cnf
ed -i "s/cluster-nodes/${CLUSTES}/g"  /etc/my.cnf.d/galera.cnf

#将此文件复制到node5、node6，注意要把 wsrep_node_name和 wsrep_node_address改成相应节点的 hostname和ip
#启动 MariaDB Galera Cluster 服务
/usr/libexec/mysqld --wsrep-new-cluster --user=root &
#for each node 
systemctl start mariadb 
#查看集群状态
mysql -uroot -p${GALERA_PASSWORD} -e "SHOW STATUS LIKE 'wsrep_%';"
}

