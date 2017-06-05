#!/bin/bash
#Wirte by keanlee on May 19th 

#------------------------------This script can help you depoly a lots of controller node and compute node 

ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"
MAGENTA="$ESC[0;35m"
YELLOW="$ESC[0;33m"
BLUE="$ESC[0;34m"
WHITE="$ESC[0;37m"
#PURPLE="$ESC[0;35m"
CYAN="$ESC[0;36m"

echo -e $CYAN $(cat ./deploy-openstack/README.txt) $NO_COLOR

debug(){
if [[ $1 -ne 0 ]]; then
echo $RED $2 $NO_COLOR
exit 1
fi
}

function help(){
cat 1>&2 <<__EOF__
$MAGENTA================================================================
              --------Usage as below ---------
           sh $0 controller  
              $BLUE#to deploy controller node$NO_COLOR 
             
           ${MAGENTA}sh $0 compute  
              $BLUE#to deploy compute node$NO_COLOR
             
           ${MAGENTA}sh $0 check  
              $BLUE#to check the target host net and disk info$NO_COLOR${MAGENTA}
================================================================
$NO_COLOR
__EOF__
}

function controller(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 
cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do scp -r deploy-openstack/ $line:/root/; debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n $line /bin/bash /root/deploy-openstack/install.sh controller | tee debug.log  ; debug "$?" "bash remote execute on remote host <$line> error "; done
}


#---------------------------------main-----------------

function compute(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 
cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do scp -r deploy-openstack/ $line:/root/; debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/deploy-openstack/install.sh compute | tee debug.log ; debug "$?" "bash remote execute on remote host <$line> error "; done
}

function check_info(){
#check the target host net and disk info
#for controller nodes
cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do scp deploy-openstack/bin/system_info.sh $line:/root/; debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1
cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/system_info.sh; debug "$?" "bash remote execute on remote host <$line> error "; done

#for compute nodes
cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do scp deploy-openstack/bin/system_info.sh $line:/root/; debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1
cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/system_info.sh; debug "$?" "bash remote execute on remote host <$line> error "; done
}

case $1 in
controller)
controller
;;
compute)
compute
;;
check)
check_info
;;
*)
help
esac
