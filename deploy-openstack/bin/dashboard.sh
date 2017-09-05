#!/bin/bash
##
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
#The Dashboard (horizon) is a web interface that enables cloud administrators and users to manage various OpenStack resources and services.


function dashboard(){

cat 2>&1 <<__EOF__
$MAGENTA==========================================================================
      Begin to deploy Dashboard on ${YELLOW}$(hostname)${NO_COLOR}${MAGENTA} which as controller node
==========================================================================
$NO_COLOR
__EOF__

function dashboard(){
echo $BLUE Install openstack-dashboard ... $NO_COLOR
yum install openstack-dashboard -y 1>/dev/null
    debug "$?" "Install openstack-dashboard failed "

echo $BLUE copy local_settings and edit it ... $NO_COLOR
cp -f ./etc/controller/dashboard/local_settings /etc/openstack-dashboard
sed -i "s/127.0.0.1/$MGMT_IP/g"  /etc/openstack-dashboard/local_settings
sed -i "s/controller/$MGMT_IP/g" /etc/openstack-dashboard/local_settings

echo $BLUE restart httpd.service and memcached.service $NO_COLOR
systemctl restart httpd.service memcached.service  
    debug "$?" "systemctl restart httpd.service memcached.service Failed "

source  $OPENRC_DIR/admin-openrc
if [[ $(openstack flavor list | grep True | wc -l) -ge 2 ]];then 
    echo $YELLOW Base flaovor has already create $NO_COLOR
else
    echo $BLUE Create flavor for openstack user ...$NO_COLOR
    openstack flavor create --id 0 --vcpus 1 --ram 512 --disk 10  m0.nano
    openstack flavor create --id 1 --vcpus 1 --ram 1024 --disk 20  m1.nano
        debug "$?"  "opnstack flavor create failed "
fi

}
dashboard
cat 2>&1 <<__EOF__
$GREEN=====================================================================================
       
   Congratulation you finished to deploy Dashboard on ${YELLOW}$(hostname)${NO_COLOR}${GREEN}
     You can log in the dasboard with below info:
                            domain: default
                            user: admin 
                            password: ${YELLOW}${ADMIN_PASS}${GREEN}

=====================================================================================
$NO_COLOR
__EOF__
}

dashboard 
