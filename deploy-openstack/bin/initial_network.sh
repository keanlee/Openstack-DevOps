#!/bin/bash 
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License
#
#author by keanlee on June 12th of 2017

#Before launching your first instance, you must create the necessary virtual network 
#infras-tructure to which the instances connect, including the external network and tenant net-work

source /home/admin-openrc


#disable ip address of devcie 

#ifconfig eth0 0

#ip addr del dev eth0 1.1.1.1/24


echo $BLUE Create external network $NO_COLOR 
#---------------- the network name ---
neutron net-create external-net --router:external=True

#Like a physical network, a virtual network requires a subnet assigned to it. 
#The external net-work shares the same subnet and gateway associated with the physical network 
#connectedto the external interface on the network node. You should specify an exclusive slice of 
#thissubnet for router and floating IP addresses 
#to prevent interference with other devices onthe external network

echo $BLUE Create the subnet for external network  $NO_COLOR
neutron subnet-create external-net $EXTERNAL_NETWORK_CIDR --name ext-subnet \ 
--enable_dhcp=False --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END \  
--gateway $EXTERNAL_NETWORK_GATEWAY

echo $BLUE Create a router $NO_COLOR 
neutron router-create pub-router

echo $BLUE Let the router connect the external network $NO_COLOR 
neutron router-gateway-set pub-router external-net


#For example 
#neutron subnet-create external-net 10.245.58.0/24 --name external_subnet \
#--enable_dhcp=False --allocation-pool start=10.245.58.2,end=10.245.58.20 \
#--gateway=10.245.58.1
