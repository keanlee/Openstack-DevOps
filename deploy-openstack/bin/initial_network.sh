#!/bin/bash 
#author by keanlee on June 12th of 2017

#Before launching your first instance, you must create the necessary virtual network 
#infras-tructure to which the instances connect, including the external network and tenant net-work

source /home/admin-openrc

echo $BLUE Create external network $NO_COLOR 
#---------------- the network name ---
neutron net-create ext-net --router:external \   
--provider:physical_network external --provider:network_type vxlan 

#Like a physical network, a virtual network requires a subnet assigned to it. 
#The external net-work shares the same subnet and gateway associated with the physical network 
#connectedto the external interface on the network node. You should specify an exclusive slice of 
#thissubnet for router and floating IP addresses 
#to prevent interference with other devices onthe external network

echo $BLUE Create the subnet $NO_COLOR
neutron subnet-create ext-net $EXTERNAL_NETWORK_CIDR --name ext-subnet \ 
--allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \  
--disable-dhcp --gateway $EXTERNAL_NETWORK_GATEWAY



