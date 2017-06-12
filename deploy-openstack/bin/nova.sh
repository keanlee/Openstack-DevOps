#!/bin/bash
#openStack Compute can scale horizontally on standard hardware, and download images to launch instances

#-----------------------Testing ----------------------
#source ./VARIABLE
#source ./common.sh
#
#debug(){
#if [[ $1 -ne 0 ]]; then
#echo $RED $2 $NO_COLOR
#exit 1
#fi
#}

#---------------compute.sh just support controller and compute parameter---------

function nova_controller(){
#nova for controllrer node 
cat 1>&2 <<__EOF__
$MAGENTA=================================================================
            Begin to deploy nova on controller node 
=================================================================
$NO_COLOR
__EOF__

database_create nova $NOVA_DBPASS
database_create nova_api $NOVA_DBPASS

create_service_credentials $NOVA_PASS nova

echo $BLUE Install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler ... $NO_COLOR 
yum install openstack-nova-api openstack-nova-conductor \
openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler  -y 1>/dev/null 
    debug "$?" "Install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler failed "

echo $BLUE Copy nova.conf and edit it ... $NO_COLOR 
cp -f ./etc/controller/nova.conf  /etc/nova/ 
sed -i "s/MY_IP/$MY_IP_CONTROLLER/g" /etc/nova/nova.conf 
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/nova/nova.conf
sed -i "s/controller/$MGMT_IP/g" /etc/nova/nova.conf
sed -i "s/NOVA_DBPASS/$NOVA_DBPASS/g" /etc/nova/nova.conf
sed -i "s/NOVA_PASS/$NOVA_PASS/g" /etc/nova/nova.conf

sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g"  /etc/nova/nova.conf
sed -i "s/METADATA_SECRET/$METADATA_SECRET/g" /etc/nova/nova.conf

echo $BLUE Populate the nova_api databases $NO_COLOR
su -s /bin/sh -c "nova-manage api_db sync" nova
    debug "$?" "nova-manage api_db sync failed "
get_database_size nova_api $NOVA_DBPASS

echo $BLUE Populate the Nova databases $NO_COLOR
su -s /bin/sh -c "nova-manage db sync" nova
    debug "$?"  "nova-manage db sync failed "
get_database_size nova $NOVA_DBPASS
echo $GREEN Populate nova database success , ignore any deprecation messages in  above output $NO_COLOR

systemctl enable openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service 1>/dev/null 2>&1 
    debug "$?" "systemctl enable nova service failed  "

systemctl start openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service
    debug "$?" "systemctl start nova service which install controller node failed "
echo $GREEN systemctl start openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service $NO_COLOR 

cat 1>&2 <<__EOF__
$GREEN=====================================================================
       
      Congratulation you finished to deploy nova on controller node
 
=====================================================================
$NO_COLOR
__EOF__
}

function nova_compute(){
#This section describes how to install and configure the Compute service on a compute node
cat 1>&2 <<__EOF__
$MAGENTA=======================================================================
      Begin to deploy nova on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as compute node
=======================================================================
$NO_COLOR
__EOF__

echo $BLUE install openstack-nova-compute ... $NO_COLOR
yum install openstack-nova-compute -y 1>/dev/null
    debug "$?" "Install openstack-nova-compute failed "

echo $BLUE Copy nova.conf and edit it ... $NO_COLOR
cp -f ./etc/compute/nova.conf  /etc/nova
sed -i "s/COMPUTE_MANAGEMENT_INTERFACE_IP_ADDRESS/$COMPUTE_MANAGEMENT_INTERFACE_IP_ADDRESS/g" /etc/nova/nova.conf
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/nova/nova.conf
sed -i "s/controller/$CONTROLLER_VIP/g" /etc/nova/nova.conf
sed -i "s/NOVA_PASS/$NOVA_PASS/g" /etc/nova/nova.conf


if [[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) = 0 ]];then 
    echo $YELLOW Your compute node does not support hardware acceleration and  configure libvirt to use QEMU instead of KVM $NO_COLOR
    sed -i "/\[libvirt\]/a\virt_type\ =\ qemu" /etc/nova/nova.conf
fi 

systemctl enable libvirtd.service openstack-nova-compute.service  1>/dev/null 2>&1
systemctl start libvirtd.service openstack-nova-compute.service  
    debug "$?" "systemctl start libvirtd or openstack-nova-compute failed \
.If the nova-compute service fails to start, check /var/log/nova/nova-compute.log.
The error message AMQP server on controller:5672 is unreachable likely indicates
that the firewall on the controller node is preventing access to port 5672"

echo $GREEN This node has alreadly runing libvirtd.service openstack-nova-compute.service $NO_COLOR 

cat 1>&2 <<__EOF__
$GREEN=========================================================================================
       
         Congratulation you finished to deploy nova on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
 
You can go to controller node to verify it by <openstack compute service list> command
=========================================================================================
$NO_COLOR
__EOF__

}

case $1 in
controller)
    nova_controller
    ;;
compute)
    nova_compute
    ;;
*)
    debug "1" "compute.sh just support controller and compute parameter, your $1 is not support "
    ;;
esac 

