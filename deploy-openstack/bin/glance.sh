#!/bin/bash 
#This script can help you to deploy glance of openstack

#The OpenStack Image service is central to Infrastructure-as-a-Service (IaaS) as shown in Conceptual architecture. 
#It accepts API requests for disk or server images, and metadata definitions from end users or OpenStack Compute components. 
#It also supports the storage of disk or server images on various repository types, including OpenStack Object Storage

function create_service_credentials(){
#This function parameter :
#$1 is the service password 
#$2 is the service name ,example nova glance neutron cinder etc. 
#

echo $BLUE To create the service credentials, complete these steps: $NO_COLOR 

source $OPENRC_DIR/admin-openrc
echo $BLUE create the service credentials: $NO_COLOR
echo $BLUE Create the glance user  $NO_COLOR
openstack user create --domain default --password $1  $2  &&

echo $BLUE Add the admin role to the $2 user and service project $NO_COLOR
openstack role add --project service --user $2 admin

echo $BLUE Create the $2 service entity $NO_COLOR
case $2 in
glance)
local SERVICE=Image
local SERVICE1=image
local PORTS=9292
;;
nova)
local SERVICE=Compute
local SERVICE1=compute
local PORTS=8774
;;
neutron)
local SERVICE=Networking
local SERVICE1=network 
local PORTS=9696
cinder)
local SERVICE=Block Storage
local PORTS=8776
#update here later 
;;
*)
debug "1" "The second parameter is the service name: nova glance neutron cinder etc,your $2 is unkown "
;;
esac 
openstack service create --name $2 --description "OpenStack ${SERVICE}" ${SERVICE1}
debug "$?" "openstack service create failed "

echo $BLUE Create the Image service API endpoints $NO_COLOR
local CLI=$(openstack endpoint create --region RegionOne)

if [[ $2 = nova ]];then 
$CLI ${SERVICE1} public http://$MGMT_IP:${PORTS}/v2.1/%\(tenant_id\)s
$CLI ${SERVICE1} internal http://$MGMT_IP:${PORTS}/v2.1/%\(tenant_id\)s
$CLI ${SERVICE1} admin http://$MGMT_IP:${PORTS}/v2.1/%\(tenant_id\)s
debug "$?" "openstack endpoint create failed "

elif [[ $2 = cinder ]];then
$CLI ${SERVICE1} public http://$MGMT_IP:${PORTS}/v1/%\(tenant_id\)s
$CLI ${SERVICE1} internal http://$MGMT_IP:${PORTS}/v1/%\(tenant_id\)s
$CLI ${SERVICE1} admin http://$MGMT_IP:${PORTS}/v1/%\(tenant_id\)s
debug "$?" "openstack endpoint create failed "

$CLI volumev2 public http://$MGMT_IP:${PORTS}/v2/%\(tenant_id\)s
$CLI volumev2 internal http://$MGMT_IP:${PORTS}/v2/%\(tenant_id\)s
$CLI volumev2 admin http://$MGMT_IP:${PORTS}/v2/%\(tenant_id\)s
debug "$?" "openstack endpoint create failed "

else 
$CLI ${SERVICE1} public http://$MGMT_IP:${PORTS}
$CLI ${SERVICE1} internal http://$MGMT_IP:${PORTS}
$CLI ${SERVICE1} admin http://$MGMT_IP:${PORTS}
debug "$?" "openstack endpoint create failed "
fi 
echo $GREEN openstack $2 endpoint create success $NO_COLOR 
}

function glance_main(){
#this function need variable:  GLANCE_DBPASS, GLANCE_PASS

#create database 
database_create glance $GLANCE_DBPASS
create_service_credentials $GLANCE_PASS glance

echo $BLUE Install openstack-glance ... $NO_COLOR
yum install openstack-glance -y  1>/dev/null
debug "$?" "Install openstack-glance failed "

#add ceph support 
#yum install python-rbd -y 1>/dev/null
#debug  "$?" "$RED Install python-rbd failed $NO_COLOR "

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

echo $BLUE Populate the Image service database $NO_COLOR
su -s /bin/sh -c "glance-manage db_sync" glance  1>/dev/null 2>&1
debug "$?" "Populate the Image service database Failed "
echo $GREEN Ignore the above  any deprecation messages in this output $NO_COLOR 

#Start the Image services and configure them to start when the system boots
systemctl enable openstack-glance-api.service openstack-glance-registry.service  1>/dev/null
systemctl start openstack-glance-api.service openstack-glance-registry.service
debug "$?"  "Start daemon openstack-glance-api openstack-glance-registry failed,Maybe you should check the conf file "
}

function verify_glance(){
echo $BLUE Verify operation of the Image service using CirrOS, a small Linux image that helps you test your OpenStack deployment $NO_COLOR
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

glance_main
verify_glance

