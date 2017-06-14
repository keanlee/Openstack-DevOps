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


debug(){
if [[ $1 -ne 0 ]]; then
    echo $RED $2 $NO_COLOR
    exit 1
fi
}

function help(){
echo -e $CYAN $(cat ./deploy-openstack/README.txt) $NO_COLOR
cat 1>&2 <<__EOF__
$MAGENTA================================================================
              --------Usage as below ---------
           sh $0 controller  
              $BLUE#to deploy controller node$NO_COLOR 
             
           ${MAGENTA}sh $0 compute  
              $BLUE#to deploy compute node$NO_COLOR
             
           ${MAGENTA}sh $0 network
              $BLUE#to deploy network node$NO_COLOR
                    
           ${MAGENTA}sh $0 controller-as-network-node
              $BLUE#to deploy controller as network node$NO_COLOR  
          
           ${MAGENTA}sh $0 check-controller 
              $BLUE#to check the controller host net and disk info$NO_COLOR${MAGENTA}

           ${MAGENTA}sh $0 check-compute
              $BLUE#to check the compute host net and disk info$NO_COLOR${MAGENTA}
================================================================
$NO_COLOR
__EOF__
}


#----------------------------------controller node deploy ---------------------
function controller(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do scp -r deploy-openstack/ \
$line:/root/; \
    debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n $line /bin/bash /root/deploy-openstack/install.sh \
controller | tee controller-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$line> error "; done

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n $line 'rm -rf /root/deploy-openstack/' ;done
}



#---------------------------------compute node deploy -----------------
function compute(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 
cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do scp -r deploy-openstack/ $line:/root/; \
    debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/deploy-openstack/install.sh \
compute | tee compute-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$line> error "; done

cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /root/deploy-openstack/';done
}




#-----------------------------show target host system info-------------------------------------
function check_info(){
#check the target host net and disk info
#for controller nodes
if [[ $1 = "controller" ]];then 
    cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do scp deploy-openstack/bin/system_info.sh $line:/root/; \
        debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1
    cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$line> error "; done
   
    cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /root/system_info.sh';done
elif [[ $1 = "compute" ]];then 
    #for compute nodes
    cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do scp deploy-openstack/bin/system_info.sh $line:/root/; \
        debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1
    cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$line> error "; done
 
   cat ./deploy-openstack/COMPUTE_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /root/system_info.sh';done
fi
}



#----------------------------------network node deploy-----------------------
function network_node(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 

cat ./deploy-openstack/NETWORK_HOSTS | while read line ; do scp -r deploy-openstack/ $line:/root/; \
    debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/NETWORK_HOSTS | while read line ; do ssh -n root@$line /bin/bash /root/deploy-openstack/install.sh \
network | tee network-node-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log;done 

cat ./deploy-openstack/NETWORK_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /root/deploy-openstack/' ;done 
}



#-----------------------------------controller as network node deploy---------------------
function controller_as_network_node(){
echo $BLUE scp deplory script to target hosts $NO_COLOR 

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do scp -r deploy-openstack/ \
$line:/root/; \
    debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n $line /bin/bash /root/deploy-openstack/install.sh \
controller-as-network-node | tee controller-network-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$line> error "; done

cat ./deploy-openstack/CONTROLLER_HOSTS | while read line ; do ssh -n $line 'rm -rf /root/deploy-openstack/' ;done
}


case $1 in
controller)
    controller
    ;;
compute)
    compute
    ;;
network)
    network_node
    ;;
check-controller)
    check_info controller 
    ;;
check-compute)
    check_info compute
    ;;
controller-as-network-node)
   controller_as_network_node
   ;;
*)
    help
esac
