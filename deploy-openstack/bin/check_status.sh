#!/bin/bash
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



