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

#keanlee on June 1st of 2017


echo $BLUE check daemon status ... $NO_COLOR

#nova controller 
openstack-nova-api.service \
openstack-nova-consoleauth.service openstack-nova-scheduler.service \
openstack-nova-conductor.service openstack-nova-novncproxy.service

#nova compute
libvirtd.service openstack-nova-compute.service

#glance 
openstack-glance-api.service openstack-glance-registry.service

#keystone dashboard 
httpd.service

#cinder controller 
 openstack-cinder-api.service openstack-cinder-scheduler.service

#cinder block node 

openstack-cinder-volume.service target.service


#neutron controller
neutron-server.service

#neutron network node 
neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service  openvswitch.service
neutron-l3-agent.service

#neutron compute node
neutron-openvswitch-agent.service
neutron-ovs-cleanup.service

source /home/admin-openrc

nova service-list

neutron agent-list

cinder service-list



