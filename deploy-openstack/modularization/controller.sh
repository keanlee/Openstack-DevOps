#!/bin/bash

function install_packages_controller(){
#-----------------install all of package of controller node ------------------------------------
    yum install openstack-selinux python-openstackclient -y 1>/dev/null 
    debug "$?" "$RED yum install openstack-selinux python-openstackclient failed $NO_COLOR"
    yum install openstack-keystone httpd mod_wsgi  memcached python-memcached -y 1>/dev/null
    debug "$?" "$RED yum install openstack-keystone failed $NO_COLOR"
    yum install openstack-glance  -y  1>/dev/null
    debug "$?" "$RED yum install openstack-glance failed $NO_COLOR"
    yum install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler -y 1>/dev/null
    debug  "$?" "$RED yum install openstack-nova-api failed $NO_COLOR"
    yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch -y 1>/dev/null
    debug  "$?" "$RED yum install openstack-neutron failed $NO_COLOR"
    yum install openstack-dashboard  -y 1>/dev/null
    debug  "$?" "$RED yum install openstack-dashboard failed $NO_COLOR"
    yum install openstack-cinder  -y 1>/dev/null
    debug  "$?" "$RED yum install openstack-cinder failed $NO_COLOR"
    yum install openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central python-ceilometerclient -y 1>/dev/null
    debug  "$?" "yum install ceilometer failed $NO_COLOR"
    yum install python-rbd -y 1>/dev/null
    debug  "$?" "yum install python-rbd failed $NO_COLOR "

}




