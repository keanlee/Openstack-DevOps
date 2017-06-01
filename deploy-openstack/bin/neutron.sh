#!/bin/bash 
#Write by keanlee on May 19th

#OpenStack Networking (neutron) allows you to create and attach interface devices managed by other OpenStack services to 
#networks. Plug-ins can be implemented to accommodate different networking equipment and software, providing flexibility to 
#OpenStack architecture and deployment.

#It includes the following components:
#neutron-server
#OpenStack Networking plug-ins and agents
#Messaging queue

#Refer https://docs.openstack.org/newton/install-guide-rdo/common/get-started-networking.html to get more info 

function neutron_controller(){
cat 1>&2 <<__EOF__
$MAGENTA=================================================================
      Begin to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as controller node
=================================================================
$NO_COLOR
__EOF__

database_create neutron  $NEUTRON_DBPASS
create_service_credentials $NEUTRON_PASS neutron

echo $BLUE Uninstall NetworkManager $NO_COLOR
yum erase NetworkManager  -y 1>/dev/null 
systemctl stop NetworkManager

#Option 1 deploys the simplest possible architecture that only supports attaching instances to provider (external) networks. 
#No self-service (private) networks, routers, or floating IP addresses. Only the admin or other privileged user can manage provider networks.

#Option 2 augments option 1 with layer-3 services that support attaching instances to self-service networks.
#The demo or other unprivileged user can manage self-service networks including routers that provide connectivity between self-service and provider networks. Additionally, 
#floating IP addresses provide connectivity to instances using self-service networks from external networks such as the Internet.

#Option 2 also supports attaching instances to provider networks
echo $BLUE Using the option 2 of neutron to deploy ... $NO_COLOR 
echo $BLUE Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ... $NO_COLOR 
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch -y 1>/dev/null
    debug "$?" "Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch failed "

echo $BLUE Copy and edite configuration file of Neutron $NO_COLOR 
cp -f ./etc/controller/neutron/neutron.conf  /etc/neutron
sed -i "s/controller/$MGMT_IP/g"  /etc/neutron/neutron.conf 
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/neutron/neutron.conf 
sed -i "s/NEUTRON_DBPASS/$NEUTRON_DBPASS/g" /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" /etc/neutron/neutron.conf
sed -i "s/NOVA_PASS/$NOVA_PASS/g"  /etc/neutron/neutron.conf

#Openvswitch 
cp -f ./etc/controller/neutron/plugin.ini  /etc/neutron/plugins/ml2/ml2_conf.ini
#No need to edit below configuration file 
#cp -f ./etc/controller/neutron/ml2_conf.ini   /etc/neutron/plugins/ml2

cp -f  ./etc/controller/neutron/dhcp_agent.ini  /etc/neutron

cp -f ./etc/controller/neutron/dnsmasq-neutron.conf /etc/neutron

cp -f ./etc/controller/neutron/l3_agent.ini    /etc/neutron
sed -i "s/br-provider/$br_provider/g"  /etc/neutron/l3_agent.ini

cp -f ./etc/controller/neutron/metadata_agent.ini  /etc/neutron 
sed -i "s/controller/$MGMT_IP/g"  /etc/neutron/metadata_agent.ini
sed -i "s/METADATA_SECRET/$METADATA_SECRET/g" /etc/neutron/metadata_agent.ini

cp -f ./etc/controller/neutron/ml2_conf.ini  /etc/neutron/plugins/ml2

cp -f ./etc/controller/neutron/openvswitch_agent.ini  /etc/neutron/plugins/ml2/
sed -i "s/LOCAL_IP/$MGMT_IP/g"  /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i "s/br-provider/$br_provider/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

chown -R root:neutron /etc/neutron/

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
    debug "$?" "ln -s failed for /etc/neutron/plugin.ini "

echo $BLUE Populate the database ...  $NO_COLOR
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron  1>/dev/null
    debug "$?" "Populate the database of neutron failed "

systemctl restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service 
    debug "$?"  "systemctl restart openstack-nova-api openstack-nova-scheduler.service openstack-nova-conductor.service failed "

systemctl enable neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service  openvswitch.service 1>/dev/null 2>&1 

#systemctl start  neutron-linuxbridge-agent.service 
#    debug "$?" "start neutron-linuxbridge-agent failed "
systemctl start  neutron-dhcp-agent.service 
    debug "$?" "start neutron-dhcp-agent failed "
systemctl start  neutron-metadata-agent.service
    debug "$?" "start neutron-metadata-agent failed "
systemctl start openvswitch.service
    debug "$?" "start openvswitch.service failed"

#for option 2
systemctl enable neutron-l3-agent.service 1>/dev/null 2>&1

systemctl start neutron-l3-agent.service
   debug "$?" "start neutron-l3-agent failed "

systemctl start  neutron-server.service
    debug "$?" "start neutron-server failed "

cat 1>&2 <<__EOF__
$GREEN=====================================================================================
       
      Congratulation you finished to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
 
=====================================================================================
$NO_COLOR
__EOF__

}

function neutron_compute(){
cat 1>&2 <<__EOF__
$MAGENTA=================================================================
      Begin to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as compute node
=================================================================
$NO_COLOR
__EOF__

echo $BLUE Uninstall NetworkManager $NO_COLOR
yum erase NetworkManager  -y 1>/dev/null
systemctl stop NetworkManager

echo $BLUE Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch $NO_COLOR 
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch -y 1>/dev/null 
#install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
    debug "$?" "Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch failed"

systemctl enable openvswitch.service  1>/dev/null 2>&1
systemctl start openvswitch.service
     debug "$?" "start openvswitch failed "    

echo $BLUE Create the OVS provider bridge ${YELLO}${br_provider}${NO_COLOR} 
ovs-vsctl add-br ${br_provider}

echo $BLUE Add the provider network interface as a port on the OVS provider bridge ${YELLO}${br_provider}${NO_COLOR}
#Replace PROVIDER_INTERFACE with the name of the underlying interface that handles provider networks. For example, eth1
ovs-vsctl add-port ${br_provider} $PROVIDER_INTERFACE

echo $BLUE Copy conf file and edit it $NO_COLOR 
cp -f ./etc/compute/neutron/neutron.conf  /etc/neutron
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/neutron/neutron.conf 
sed -i "s/controller/$CONTROLLER_VIP/g"  /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" /etc/neutron/neutron.conf

cp -f ./etc/compute/neutron/dhcp_agent.ini  /etc/neutron
cp -f ./etc/compute/neutron/l3_agent.ini  /etc/neutron
sed -i "s/br-ex/${br_provider}/g"   /etc/neutron/l3_agent.ini

cp -f ./etc/compute/neutron/metadata_agent.ini  /etc/neutron
sed -i "s/CONTROLLER_VIP/${CONTROLLER_VIP}/g"   /etc/neutron/metadata_agent.ini
sed -i "s/METADATA_SECRET/${METADATA_SECRET}/g"  /etc/neutron/metadata_agent.ini

cp -f ./etc/compute/neutron/openvswitch_agent.ini  /etc/neutron
sed -i "s/LOCAL_IP/$MGMT_IP/g" /etc/neutron/openvswitch_agent.ini
sed -i "s/br-provider/${br_provider}/g"  /etc/neutron/openvswitch_agent.ini

#cp -f ./etc/compute/neutron/linuxbridge_agent.ini  /etc/neutron/plugins/ml2
#sed -i "s/PROVIDER_INTERFACE_NAME/$COMPUTE_PROVIDER_INTERFACE_NAME/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#sed -i "s/OVERLAY_INTERFACE_IP_ADDRESS/$COMPUTE_OVERLAY_INTERFACE_IP_ADDRESS/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g"  /etc/nova/nova.conf

systemctl restart openstack-nova-compute.service
    debug "$?" "restart openstack-nova-compute failed after install neutron on compute node "
systemctl enable neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service  neutron-metadata-agent.service neutron-ovs-cleanup.service 1>/dev/null 2>&1
systemctl start neutron-openvswitch-agent.service neutron-l3-agent.service neutron-metadata-agent.service neutron-dhcp-agent.service
    debug "$?" "start neutron-openvswitch-agent.service neutron-l3-agent.service neutron-metadata-agent.service failed "


cat 1>&2 <<__EOF__
$GREEN=====================================================================================
       
      Congratulation you finished to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
Verify it by below command on Controller node: 
   execute: <neutron ext-list> 
   option2: <openstack network agent list>
=====================================================================================
$NO_COLOR
__EOF__

}


case $1 in
controller)
neutron_controller
;;
compute)
neutron_compute
;;
*)
debug "1" "neutron.sh just support controller and compute parameter, your $1 is not support "
;;
esac
