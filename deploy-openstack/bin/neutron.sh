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
      Begin to deploy Neutron on ${YELLOW}$(hostname)${NO_COLOR}${GREEN} which as controller node
=================================================================
$NO_COLOR
__EOF__

database_create neutron $NEUTRON_DBPAS
create_service_credentials $NEUTRON_PASS neutron

#Option 1 deploys the simplest possible architecture that only supports attaching instances to provider (external) networks. 
#No self-service (private) networks, routers, or floating IP addresses. Only the admin or other privileged user can manage provider networks.

#Option 2 augments option 1 with layer-3 services that support attaching instances to self-service networks.
#The demo or other unprivileged user can manage self-service networks including routers that provide connectivity between self-service and provider networks. Additionally, 
#floating IP addresses provide connectivity to instances using self-service networks from external networks such as the Internet.

#Option 2 also supports attaching instances to provider networks
echo $BLUE Using the option 2 of neutron ... $NO_COLOR 
echo $Blue Install openstack-neutron openstack-neutron-ml2  openstack-neutron-linuxbridge ebtables ... $NO_COLOR 
yum install openstack-neutron openstack-neutron-ml2  openstack-neutron-linuxbridge ebtables 1>/dev/null
debug "$?" "Install openstack-neutron openstack-neutron-ml2  openstack-neutron-linuxbridge ebtables failed "

echo $BLUE Copy and edite configuration file of Neutron $NO_COLOR 
cp -f ./etc/neutron/neutron.conf  /etc/neutron
sed -i "s/controller/$MGMT_IP/g"  /etc/neutron/neutron.conf 
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g" /etc/neutron/neutron.conf 
sed -i "s/NEUTRON_DBPASS/$NEUTRON_DBPASS/g" /etc/neutron/neutron.conf
sed -i "s/NEUTRON_PASS/$NEUTRON_PASS/g" /etc/neutron/neutron.conf
sed -i "s/NOVA_PASS/$NOVA_PASS/g"  /etc/neutron/neutron.conf

#No need to edit below configuration file 
cp -f ./etc/neutron/ml2_conf.ini   /etc/neutron/plugins/ml2

cp -f ./etc/neutron/linuxbridge_agent.ini  /etc/neutron/plugins/ml2/
sed -i "s/PROVIDER_INTERFACE_NAME/$PROVIDER_INTERFACE_NAME/g"   /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i


cat 1>&2 <<__EOF__
$GREEN=====================================================================================
       
      Congratulation you finished to deploy Netron on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
 
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
