#!/bin/bash 

#

function cinder_controller(){
cat 1>&2 <<__EOF__
$MAGENTA=================================================================
      Begin to deploy Cinder on ${YELLOW}$(hostname)${NO_COLOR}${GREEN} which as controller node
=================================================================
$NO_COLOR
__EOF__

database_create  cinder $CINDERDB_PASS

create_service_credentials  $CINDER_PASS  cinder 

echo $BLUE Install openstack-cinder on ${YELLOW}$(hostname)$NO_COLOR 
yum install openstack-cinder -y  1>/dev/null 
debug "$?" "Install openstack-cinder on ${YELLOW}$(hostname)$NO_COLOR $RED failed "

echo $BLUE copy the cinder conf file and edit it $NO_COLOR 
cp -f ./etc/cinder.conf  /etc/cinder 
sed -i "s/controller/$MGMT_IP/g"   /etc/cinder/cinder.conf
sed -i "s/RABBIT_PASS/$RABBIT_PASS/g"  /etc/cinder/cinder.conf
sed -i "s/MY_IP/$MY_IP/g"   /etc/cinder/cinder.conf
sed -i "s/CINDER_DBPASS/$CINDERDB_PASS/g"  /etc/cinder/cinder.conf
sed -i "s/CINDER_PASS/$CINDER_PASS/g"  /etc/cinder/cinder.conf

echo $BLUE Populate the Block Storage database ... $NO_COLOR 
su -s /bin/sh -c "cinder-manage db sync" cinder
debug "$?"  "Populate the Block Storage database failed "
echo $GREEN populate the cinder database success ! Ignore any deprecation messages in above output $NO_COLOR 

systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service  1>/dev/null 2>&1 
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
debug "$?" "start openstack-cinder-api or cinder-scheduler failed "

cat 1>&2 <<__EOF__
$GREEN=====================================================================================
       
      Congratulation you finished to deploy Cinder on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
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
#update this later for compute
;;
*)
debug "1" "cinder.sh just support controller and compute parameter, your $1 is not support "
;;
esac



