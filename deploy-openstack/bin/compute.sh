#!/bin/bash
#openStack Compute can scale horizontally on standard hardware, and download images to launch instances

function nova_controller(){
#nova for controllrer node 
cat 1>&2 <<__EOF__
$MAGENTA=================================================================
            Begin to deploy nova on controller node 
=================================================================
$NO_COLOR
__EOF__

database_create nova $NOVA_DBPASS
database_create nova_api $NOVA_API_DBPASS

create_service_credentials $NOVA_PASS nova

echo $BLUE Install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler ... $NO_COLOR 
yum install openstack-nova-api openstack-nova-conductor \
openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler  -y 1>/dev/null 
debug "$?" "Install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler failed "

echo $BLUE Copy nova.conf and edit it ... $NO_COLOR 
cp -f ./etc/nova.conf  /etc/nova/ 
sed -i "s/MY_IP/$MY_IP/g" /etc/nova/nova.conf 
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/nova/nova.conf
sed -i "s/controller/$MGMT_IP/g" /etc/nova/nova.conf
sed -i "s/NOVA_DBPASS/$NOVA_DBPASS/g" /etc/nova/nova.conf
sed -i "s/NOVA_PASS/$NOVA_PASS/g" /etc/nova/nova.conf

echo $BLUE Populate the Compute databases $NO_COLOR
su -s /bin/sh -c "nova-manage api_db sync" nova
debug "$?" "nova-manage api_db sync failed "
su -s /bin/sh -c "nova-manage db sync" nova
debug "$?"  "nova-manage db sync failed "

systemctl enable openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service 1>/dev/null 
debug "$?" "systemctl enable nova service which install controller node failed "

systemctl start openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service
debug "$?" "systemctl start nova service which install controller node failed "

cat 1>&2 <<__EOF__
$MAGENTA=================================================================
       
      Congratulation you finished to deploy nova on controller node
 
=================================================================
$NO_COLOR
__EOF__
}
function nova_compute(){

yum install openstack-nova-compute -y 1>/dev/null


}
nova_controller

