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
#cp -f  ./configuration-files/glance/ceph/*  /etc/ceph
#chown glance:glance /etc/ceph/ceph.client.glance.keyring

#cp glance-api.conf and edit it 
cp -f  ./configuration-files/glance-api.conf  /etc/glance/
#change all controller as mgmg ip
sed -i "s/controller/$MGMT_IP/g"  /etc/glance/glance-api.conf
#change the glance password for keystone 
sed -i "s/GLANCE_PASS/$GLANCE_PASS/g"  /etc/glance/glance-api.conf

cp -f ./configuration-files/glance-registry.conf  /etc/glance/
sed -i "s/GLANCE_DBPASS/$GLANCE_DBPASS/"  /etc/glance/glance-registry.conf
sed -i "s/controller/$MGMT_IP/g"  /etc/glance/glance-registry.conf

#Populate the Image service database
su -s /bin/sh -c "glance-manage db_sync" glance  1>/dev/null 2>&1
#Ignore any deprecation messages in this output

#Start the Image services and configure them to start when the system boots
systemctl enable openstack-glance-api.service openstack-glance-registry.service  1>/dev/null
systemctl start openstack-glance-api.service openstack-glance-registry.service
debug "$?"  "Start daemon openstack-glance-api openstack-glance-registry failed,Maybe you should check the conf file "
function verify_glance(){
#Verify operation of the Image service using CirrOS, a small Linux image that helps you test your OpenStack deployment
source $OPENRC_DIR/admin-openrc
echo $BLUE Download the cirros image to Verfiy Glance whether or not work $NO_COLOR
#add adjust if download wget later 
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img   &&
echo $BLUE Upload the image to the Image service using the QCOW2 disk format, 
bare container format, and public visibility so all projects can access it $NO_COLOR
openstack image create "cirros" \
--file ./cirros-0.3.4-x86_64-disk.img \
--disk-format qcow2 --container-format bare \
--public
debug "$?" "Upload image to glance failed"
if [[  $(openstack image list | grep cirros | wc -l) = 1 ]];then 
echo $GREEN Upload image cirros Success $NO_COLOR
else 
echo $RED Upload image cirros Failed $NO_COLOR
fi
#need update later 
}
#if need to verfiy glance ?
verify_glance
}
glance
