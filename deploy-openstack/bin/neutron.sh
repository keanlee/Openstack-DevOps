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
#refer https://wenku.baidu.com/view/46ced95180eb6294dc886c5b.html?pn=88 for openvswitch guide 


#----------------------------------------------------neutron for controller node ----------------------
function neutron_controller(){
cat 2>&1 <<__EOF__
$MAGENTA=================================================================
      Begin to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as controller node
=================================================================
$NO_COLOR
__EOF__

database_create neutron  $NEUTRON_DBPASS
create_service_credentials $NEUTRON_PASS neutron

#Option 1 deploys the simplest possible architecture that only supports attaching instances to provider (external) networks. 
#No self-service (private) networks, routers, or floating IP addresses. Only the admin or other privileged user can manage provider networks.

#Option 2 augments option 1 with layer-3 services that support attaching instances to self-service networks.
#The demo or other unprivileged user can manage self-service networks including routers that provide connectivity between self-service and provider networks. Additionally, 
#floating IP addresses provide connectivity to instances using self-service networks from external networks such as the Internet.

#Option 2 also supports attaching instances to provider networks
echo $BLUE Using the option 2 of neutron to deploy ... $NO_COLOR 

echo $BLUE Install openstack-neutron openstack-neutron-ml2 ... $NO_COLOR 
yum install openstack-neutron openstack-neutron-ml2 -y 1>/dev/null
    debug "$?" "Install openstack-neutron openstack-neutron-ml2  failed "

echo $BLUE Copy and edit neutron.conf $NO_COLOR 
cp -f ./etc/controller/neutron/neutron.conf  /etc/neutron
sed -i "s/controller/$MGMT_IP/g"  /etc/neutron/neutron.conf 
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/neutron/neutron.conf 
sed -i "s/NEUTRON_DBPASS/$NEUTRON_DBPASS/g" /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" /etc/neutron/neutron.conf
sed -i "s/NOVA_PASS/$NOVA_PASS/g"  /etc/neutron/neutron.conf

echo $BLUE Copy plugin.ini file $NO_COLOR
cp -f ./etc/controller/neutron/plugin.ini  /etc/neutron/plugins/ml2/ml2_conf.ini

#The Networking service initialization scripts expect a symbolic link /etc/neutron/plugin.ini 
#pointing to the ML2 plug-in configuration file, /etc/neutron/plugins/ml2/ml2_conf.ini
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
    debug "$?" "ln -s failed for /etc/neutron/plugin.ini "

echo $BLUE Populate the database ...  $NO_COLOR
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron  1>/dev/null 2>&1
    get_database_size neutron $NEUTRON_DBPASS
    debug "$?" "Populate the database of neutron failed "


echo $BLUE restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service $NO_COLOR
systemctl restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service 
    debug "$?"  "systemctl restart openstack-nova-api openstack-nova-scheduler.service openstack-nova-conductor.service failed "

echo $BLUE start neutron-server.service $NO_COLOR
systemctl enable neutron-server.service 1>/dev/null 2>&1 
systemctl start  neutron-server.service
    debug "$?" "start neutron-server failed "

cat 1>&2 <<__EOF__
$GREEN=====================================================================================
       
   Congratulation you finished to deploy Neutron server on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
     Want to list loaded extensions to verify successful ?
                run <neutron ext-list> command 
 
=====================================================================================
$NO_COLOR
__EOF__

}


#--------------------------------------------------neutron for compute node -----------------------------
function neutron_compute(){
cat 2>&1 <<__EOF__
$MAGENTA====================================================================
  Begin to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as compute node
====================================================================
$NO_COLOR
__EOF__

#The compute node handles connectivity and security groups for instances

echo $BLUE To configure prerequisites: configure certain kernel networking parameters $NO_COLOR
cat >> /etc/sysctl.conf << __EOF__
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
__EOF__
sysctl -p 1>/dev/null 

echo $BLUE Install openstack-neutron-ml2 openstack-neutron-openvswitch $NO_COLOR 
yum install openstack-neutron-ml2 openstack-neutron-openvswitch -y 1>/dev/null 
#install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
    debug "$?" "Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch failed"

systemctl enable openvswitch.service  1>/dev/null 2>&1
systemctl start openvswitch.service
     debug "$?" "start openvswitch failed "    

echo $BLUE Copy conf file and edit it $NO_COLOR 
cp -f ./etc/compute/neutron/neutron.conf  /etc/neutron
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/neutron/neutron.conf 
sed -i "s/controller/$CONTROLLER_VIP/g"  /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" /etc/neutron/neutron.conf

cp -f ./etc/compute/neutron/openvswitch_agent.ini  /etc/neutron/plugins/ml2
sed -i "s/LOCAL_IP/$MGMT_IP/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i "s/br-provider/${br_provider}/g"  /etc/neutron/plugins/ml2/openvswitch_agent.ini

sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g"  /etc/nova/nova.conf

chown -R root:neutron /etc/neutron/

echo $BLUE Rstart openstack-nova-compute.service $NO_COLOR
systemctl restart openstack-nova-compute.service
    debug "$?" "restart openstack-nova-compute failed after install neutron on compute node "

echo $BLUE start neutron-openvswitch-agent.service $NO_COLOR
systemctl enable neutron-openvswitch-agent.service  neutron-ovs-cleanup.service 1>/dev/null 2>&1
systemctl start neutron-openvswitch-agent.service  
    debug "$?" "start neutron-openvswitch-agent.service failed "

cat 2>&1 <<__EOF__
$MAGENTA=====================================================================================
       
 Congratulation you finished to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA}
 Verify it by below command on Controller node: 
   execute: <neutron ext-list> 
          : <neutron agent-list>
=====================================================================================
$NO_COLOR
__EOF__

}


#------------------------------------------neutron for network node -----------------------
function neutron_network_node(){
cat 2>&1 <<__EOF__
$MAGE=====================================================================================
       
      Begin to deploy Neutron as network node on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
 
=====================================================================================
$NO_COLOR
__EOF__

#The network node primarily handles internal and external routing and DHCP services for vir-tual networks
#floating ip mapping 


echo $BLUE To configure prerequisites:configure certain kernel networking parameters $NO_COLOR
cat >> /etc/sysctl.conf << __EOF__
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
__EOF__
sysctl -p 1>/dev/null

echo $BLUE Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ... $NO_COLOR
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch -y 1>/dev/null
    debug "$?" "Install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch failed "

#add network node on controller or compute node  
if [[ $1 = "controller" || $1 = "compute" ]];then 
    break
else 
    echo $BLUE Copy and edit configuration file of network node $NO_COLOR 
    cp -f ./etc/network/neutron.conf  /etc/neutron
    sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/neutron/neutron.conf 
    sed -i "s/controller/$CONTROLLER_VIP/g"  /etc/neutron/neutron.conf
    sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" /etc/neutron/neutron.conf
fi

cp -f  ./etc/network/dhcp_agent.ini  /etc/neutron
cp -f ./etc/network/dnsmasq-neutron.conf /etc/neutron


#The Layer-3 (L3) agent provides routing services for virtual networks
cp -f ./etc/network/l3_agent.ini    /etc/neutron
sed -i "s/br-provider/$br_provider/g"  /etc/neutron/l3_agent.ini

cp -f ./etc/network/metadata_agent.ini  /etc/neutron 
sed -i "s/controller/$MGMT_IP/g"  /etc/neutron/metadata_agent.ini
sed -i "s/METADATA_SECRET/$METADATA_SECRET/g" /etc/neutron/metadata_agent.ini

local CPUs=$(lscpu | grep ^CPU\(s\) | awk -F ":" '{print $2}')
local HALFcpus=$(expr $CPUs / 2)
sed -i "s/valuesnumber/${HALFcpus}/g" /etc/neutron/metadata_agent.ini
echo $BLUE set the metadata_workers value as ${YELLOW}$HALFcpus $NO_COLOR

#The ML2 plug-in uses the Open vSwitch (OVS) mechanism (agent) to build the virtual net-working framework for instances
cp -f ./etc/network/openvswitch_agent.ini  /etc/neutron/plugins/ml2/
sed -i "s/LOCAL_IP/$MGMT_IP/g"  /etc/neutron/plugins/ml2/openvswitch_agent.ini
sed -i "s/br-provider/$br_provider/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini

chown -R root:neutron /etc/neutron/

systemctl enable neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service  openvswitch.service 1>/dev/null 2>&1 

if [[ $1 = "compute" ]];then 
    systemctl restart openvswitch.service
else 
    systemctl start openvswitch.service
        debug "$?" "start openvswitch.service failed"
fi


echo $BLUE Create the OVS provider bridge ${YELLOW}${br_provider}${NO_COLOR} 
PROVIDER_INTER_ADRR=$(ip addr show ${PROVIDER_INTERFACE} | grep 'inet[^6]' | sed -n '1p' | awk '{print $2}')
if [[ $PROVIDER_INTER_ADRR != "" ]];then
     echo $BLUE Please ignore the above error output $NO_COLOR
     echo $BLUE Disable ${YELLOW}${PROVIDER_INTERFACE}${BLUE} ip address $NO_COLOR 
     ip addr del dev ${PROVIDER_INTERFACE} ${PROVIDER_INTER_ADRR}
fi 

if  [[ -e /etc/sysconfig/network-scripts/ifcfg-${br_provider} ]];then
    if [[ $(cat /etc/sysconfig/network-scripts/ifcfg-${PROVIDER_INTERFACE} | grep -i onboot=\"yes\" | wc -l) -eq 1 ]];then 
        sed -i "s/ONBOOT=\"yes\"/ONBOOT=\"no\"/g" /etc/sysconfig/network-scripts/ifcfg-${PROVIDER_INTERFACE}
    fi
fi

ovs-vsctl add-br ${br_provider}

echo $BLUE Add the provider network interface:$YELLOW$PROVIDER_INTERFACE$BLUE as a port on the OVS provider bridge ${YELLOW}${br_provider}${NO_COLOR}
#Replace PROVIDER_INTERFACE with the name of the underlying interface that handles provider networks. For example, eth1
ovs-vsctl add-port ${br_provider} $PROVIDER_INTERFACE
echo $BLUE Add port $YELLOW$PROVIDER_INTERFACE$BLUE to $br_provider $NO_COLOR 

#Depending on your network interface driver, you may need to disable generic receive offload (GRO) to achieve 
#suitable throughput between yourinstances and the external network
ethtool -K $PROVIDER_INTERFACE gro off


echo $BLUE start neutron-dhcp-agent.service and neutron-metadata-agent.service $NO_COLOR
systemctl start  neutron-dhcp-agent.service 
    debug "$?" "start neutron-dhcp-agent failed "
systemctl start  neutron-metadata-agent.service
    debug "$?" "start neutron-metadata-agent failed "

echo $BLUE start neutron-openvswitch-agent.service $NO_COLOR
systemctl start  neutron-openvswitch-agent.service
    debug "$?" "start neutron-openvswitch-agent failed "

#for option 2
echo $BLUE start neutron-l3-agent $NO_COLOR
systemctl enable neutron-l3-agent.service 1>/dev/null 2>&1
systemctl start neutron-l3-agent.service
   debug "$?" "start neutron-l3-agent failed "

cat 2>&1 <<__EOF__
$GREEN=====================================================================================
       
 Congratulation you finished to deploy Neutron as network node on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
 Verify it by below command on Controller node: 
   execute: <neutron ext-list> 
            <neutron agent-list>
=====================================================================================
$NO_COLOR
__EOF__
}



#--------------------------------------------Main--------------------------------------------
case $1 in
controller)
    neutron_controller
    ;;
compute)
    neutron_compute
    ;;
network)
    neutron_network_node
    ;;
controller-as-network-node)
    echo $YELLOW You will deploy network node on controller ... $NO_COLOR
    neutron_controller
    neutron_network_node controller 
    ;;
compute-as-network-node)
    echo $YELLOW You will deploy network node on compute ... $NO_COLOR
    neutron_compute
    neutron_network_node compute
    ;;
*)
    debug "1" "neutron.sh just support controller ,network , compute and controller-as-network-node neutron_network_node compute parameter, your $1 is not support "
    ;;
esac
