#!/bin/bash 
#will add ceph support later 

function cinder_controller(){
cat 2>&1 <<__EOF__
$MAGENTA=============================================================================
      Begin to deploy Cinder on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as controller node
=============================================================================
$NO_COLOR
__EOF__

database_create  cinder $CINDERDB_PASS

create_service_credentials $CINDER_PASS cinder 

echo $BLUE Install openstack-cinder on ${YELLOW}$(hostname)$NO_COLOR 
yum install openstack-cinder -y  1>/dev/null 
    debug "$?" "Install openstack-cinder on ${YELLOW}$(hostname)$NO_COLOR $RED failed "

echo $BLUE copy the cinder conf file and edit it $NO_COLOR 
cp -f ./etc/controller/cinder.conf  /etc/cinder 
sed -i "s/controller/$MGMT_IP/g"   /etc/cinder/cinder.conf
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g"  /etc/cinder/cinder.conf
sed -i "s/MY_IP/$MY_IP/g"   /etc/cinder/cinder.conf
sed -i "s/CINDER_DBPASS/$CINDERDB_PASS/g"  /etc/cinder/cinder.conf
sed -i "s/CINDER_PASS/$CINDER_PASS/g"  /etc/cinder/cinder.conf

echo $BLUE Populate the Block Storage database ... $NO_COLOR 
su -s /bin/sh -c "cinder-manage db sync" cinder  1>/dev/null 2>&1
    get_database_size cinder $CINDERDB_PASS
    debug "$?"  "Populate the Block Storage database failed "
echo $GREEN populate the cinder database success ! Ignore any deprecation messages in above output $NO_COLOR 

systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service  openstack-cinder-backup.service 1>/dev/null 2>&1 
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service  openstack-cinder-backup.service
    debug "$?" "start openstack-cinder-api or cinder-scheduler failed "

cat 2>&1 <<__EOF__
$GREEN=====================================================================================
       
      Congratulation you finished to deploy Cinder on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
=====================================================================================
$NO_COLOR
__EOF__

}

function cinder_compute(){
cat 2>&1 <<__EOF__
$MAGENTA=====================================================================
      Begin to deploy Cinder on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as compute/block node
=====================================================================
$NO_COLOR
__EOF__

echo $BLUE Install lvm2  $NO_COLOR
yum install lvm2 -y 1>/dev/null
echo $BLUE Your partitions is below:      $NO_COLOR 
lsblk
echo $BLUE Partitioned disk: $NO_COLOR 
cat /proc/partitions | awk '{print $4}' | sed -n '3,$p' | grep "[a-z]$"
systemctl enable lvm2-lvmetad.service   1>/dev/null 2>&1
systemctl start lvm2-lvmetad.service
debug "$?" "start lvm2-lvmetad failed "

echo $YELLOW Please choose one form above output to create the LVM physical volume $NO_COLOR
#read 
PARTITION=sde

echo $BLUE Create the LVM physical volume /dev/$PARTITION: $NO_COLOR 
pvcreate /dev/$PARTITION
debug "$?" "pvcreate /dev/$PARTITION failed "

echo $BLUE Create the LVM volume group cinder-volumes: $NO_COLOR
vgcreate cinder-volumes /dev/$PARTITION
debug "$?"  "vgcreate cinder-volumes /dev/$PARTITION failed"

#Each item in the filter array begins with a for accept or r for reject and includes a regular expression for the device name. 
#The array must end with r/.*/ to reject any remaining devices. You can use the vgs -vvvv command to test filters
#refer https://docs.openstack.org/newton/install-guide-rdo/cinder-storage-install.html
sed -i "/\# Configuration option devices\/dir./a\        filter = [ \"a/${PARTITION}/\", \"r/.*/\"]"  /etc/lvm/lvm.conf

echo $BLUE Install openstack-cinder targetcli python-keystone ... $NO_COLOR
yum install openstack-cinder targetcli python-keystone -y 1>/dev/null
debug "$?" "Install openstack-cinder targetcli python-keystone failed "

echo $BLUE Copy cinder.conf and edit it $NO_COLOR 
cp -f ./etc/compute/cinder.conf  /etc/cinder
sed -i "s/controller/$CONTROLLER_VIP/g"   /etc/cinder/cinder.conf
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g"  /etc/cinder/cinder.conf
sed -i "s/LOCAL_MGMT_IP/$MGMT_IP/g"  /etc/cinder/cinder.conf
sed -i "s/CINDER_DBPASS/$CINDERDB_PASS/g"  /etc/cinder/cinder.conf
sed -i "s/CINDER_PASS/$CINDER_PASS/g"   /etc/cinder/cinder.conf

systemctl enable openstack-cinder-volume.service target.service  1>/dev/null 2>&1
systemctl start openstack-cinder-volume.service target.service
debug "$?"  "start openstack-cinder-volume.service target.service failed "

cat 2>&1 <<__EOF__
$GREEN=====================================================================================
       
Congratulation you finished to deploy Cinder on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
  You can go to controller node to Verify by <openstack volume service list> 

=====================================================================================
$NO_COLOR
__EOF__


}

case $1 in
controller)
    cinder_controller
    ;;
compute)
    cinder_compute
    ;;
*)
    debug "1" "cinder.sh just support controller and compute parameter, your $1 is not support "
    ;;
esac



