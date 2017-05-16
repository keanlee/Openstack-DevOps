#!/bin/bash 
#This script can help you to deploy glance of openstack

#The OpenStack Image service is central to Infrastructure-as-a-Service (IaaS) as shown in Conceptual architecture. 
#It accepts API requests for disk or server images, and metadata definitions from end users or OpenStack Compute components. 
#It also supports the storage of disk or server images on various repository types, including OpenStack Object Storage

function glance(){
#this function need variable:  GLANCE_DBPASS, GLANCE_PASS

#create database 
database_create glance $GLANCE_DBPASS

source /root/admin-openrc
#create the service credentials:
#Create the glance user
openstack user create --domain default --password $GLANCE_PASS glance  &&
#Add the admin role to the glance user and service project
openstack role add --project service --user glance admin
#Create the glance service entity
openstack service create --name glance --description "OpenStack Image" image
#Create the Image service API endpoints
openstack endpoint create --region RegionOne image public http://$MGMT_IP:9292
openstack endpoint create --region RegionOne image internal http://$MGMT_IP:9292
openstack endpoint create --region RegionOne image admin http://$MGMT_IP:9292

#Install packages 
yum install openstack-glance -y  1>/dev/null
debug "$?" "Install openstack-glance failed "

#add ceph support 
yum install python-rbd -y 1>/dev/null
debug  "$?" "$RED Install python-rbd failed $NO_COLOR "

#--------add ceph support 
#mkdir -p  /etc/ceph
#cp -f  `pwd`/$VERSION/controller/glance/ceph/*  /etc/ceph
#chown glance:glance /etc/ceph/ceph.client.glance.keyring

#cp glance-api.conf and edit it 
cp -f  ./configuration-files/glance-api.conf  /etc/glance/
sed -i "s/controller/$MGMT_IP/g"  /etc/glance/glance-api.conf
sed -i "s/GLANCE_PASS/$GLANCE_PASS/g"  /etc/glance/glance-api.conf



}
