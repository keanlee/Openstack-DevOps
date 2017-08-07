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

option=(
help
ssh-key-all
ssh-key-compute
ssh-key-controller
ssh-key-network
check-all
check-controller
check-compute
check-network
deploy-all
deploy-controller-node
deploy-compute-node
deploy-network-node
deploy-controller-as-network-node
deploy-compute-as-network-node
galera-cluster
exit
)

source ./deploy-openstack/HOSTS

debug(){
if [[ $1 -ne 0 ]]; then
    echo $RED $2 $NO_COLOR
    exit 1
fi
}

function help(){
which pv 1>/dev/null 2>&1 || rpm -ivh ./deploy-openstack/lib/pv* 1>/dev/null 2>&1
    debug "$?" "install pv failed "
echo -e $CYAN $(cat ./deploy-openstack/README.txt) $NO_COLOR | pv -qL 30
cat 1>&2 <<__EOF__
$MAGENTA==================================================================================
              --------Usage as below ---------
           sh $0 deploy-controller-node 
              $BLUE#to deploy controller node$NO_COLOR 
             
           ${MAGENTA}sh $0 deploy-compute-node
              $BLUE#to deploy compute node$NO_COLOR
             
           ${MAGENTA}sh $0 deploy-network-node
              $BLUE#to deploy network node$NO_COLOR
                    
           ${MAGENTA}sh $0 deploy-all
              $BLUE#to deploy controller node ,network node,compute node$NO_COLOR

           ${MAGENTA}sh $0 deploy-controller-as-network-node
              $BLUE#to deploy controller as network node$NO_COLOR  
           
           ${MAGENTA}sh $0 deploy-compute-as-network-node
              $BLUE#to deploy compute as network node$NO_COLOR

           ${MAGENTA}sh $0 check-controller 
              $BLUE#to check the controller node system info$NO_COLOR${MAGENTA}

           ${MAGENTA}sh $0 check-compute
              $BLUE#to check the compute node system info$NO_COLOR${MAGENTA}

           ${MAGENTA}sh $0 check-network
              $BLUE#to check the network node system info$NO_COLOR${MAGENTA}
          
           ${MAGENTA}sh $0 check-all
              $BLUE#to check all node system info $NO_COLOR

           ${MAGENTA}sh $0 ssh-key-<target-hosts-role>
              $BLUE#to create ssh-key and copy it to target hosts 
            (target-hosts-role=controller,compute,network,storage,all)$NO_COLOR${MAGENTA}
==================================================================================
$NO_COLOR
__EOF__
}

function ssh_key(){
if [[ -e ~/.ssh/id_rsa.pub ]];then 
    break
else 
    echo $BLUE Generating public/private rsa key pair: $NO_COLOR
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    #-N "" tells it to use an empty passphrase (the same as two of the enters in an interactive script)
    #-f my.key tells it to store the key into my.key (change as you see fit).
fi 

which sshpass 1>/dev/null 2>&1 || rpm -ivh ./deploy-openstack/lib/sshpass* 1>/dev/null 2>&1   

echo -n $BLUE Please type the correct password for server:  $NO_COLOR
read Password

if [[ $1 = "compute" ]];then 
echo $BLUE copy public key to compute hosts:  $NO_COLOR
for ips in ${COMPUTE_NODE_IP[*]};
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in ${COMPUTE_NODE_IP[*]};
    do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub  $ips
done 

elif [[ $1 = "controller" ]];then
echo $BLUE copy public key to controller hosts: $NO_COLOR
for ips in ${CONTROLLER_IP[*]};
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in ${CONTROLLER_IP[*]};
   do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub  $ips;
done

elif [[ $1 = "network" ]];then
echo $BLUE copy public key to network hosts:  $NO_COLOR
for ips in ${NETWORK_NODE_IP[*]};
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in ${NETWORK_NODE_IP[*]};
    do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub  $ips;
done

elif [[ $1 = "storage" ]];then
echo $BLUE copy public key to storage hosts:  $NO_COLOR
for ips in ${BLOCK_NODE_IP[*]};
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in ${BLOCK_NODE_IP[*]};
    do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub  $ips;
done

fi
}



#----------------------------------controller node deploy ---------------------
function controller(){
if [[ $# -eq 0 ]];then
    local SCRIPT=install.sh
    local VALUE=controller
elif [[ $1 = "controller-as-network-node" ]];then 
    local SCRIPT=install.sh
    local VALUE=controller-as-network-node
elif [[ $1 = "galera" ]];then 
    local SCRIPT=bin/ha_proxy.sh galera
    local VALUE=galera
else 
    debug "1" "function cannot support your parameter "
fi 

for ips in ${CONTROLLER_IP[*]}; do scp -r deploy-openstack/ \
$ips:/home/; \
    debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1

for ips in ${CONTROLLER_IP[*]}; do ssh -n $ips /bin/bash /home/deploy-openstack/${SCRIPT} \
${VALUE} | tee ./log/${VALUE}-$ips-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$ips> error "; done

for ips in ${CONTROLLER_IP[*]}; do ssh -n $ips 'rm -rf /home/deploy-openstack/' ;done
}



#---------------------------------compute node deploy -----------------
function compute(){
if [[ $# -eq 0 ]];then
    local VALUE=compute
elif [[ $1 = "compute-as-network-node" ]];then 
    local VALUE=compute-as-network-node
else 
    debug "1" "function cannot support your parameter "
fi 


for ips in ${COMPUTE_NODE_IP[*]}; do scp -r deploy-openstack/ $ips:/home/; \
    debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1 

for ips in ${COMPUTE_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/deploy-openstack/install.sh \
${VALUE} | tee ./log/${VALUE}-$ips-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$ips> error "; done

for ips in ${COMPUTE_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/deploy-openstack/';done

}


#----------------------------------network node deploy-----------------------
function network_node(){

for ips in ${NETWORK_NODE_IP[*]} ; do scp -r deploy-openstack/ $ips:/home/; \
    debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1

for ips in ${NETWORK_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/deploy-openstack/install.sh \
network | tee ./log/network-node-$ips-$(date "+%Y-%m-%d--%H:%M")-debug.log;done 

for ips in ${NETWORK_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/deploy-openstack/' ;done 
}




#-----------------------------show target host system info-------------------------------------
function check_info(){
#check the target host system infor
#for controller nodes
if [[ $1 = "controller" ]];then 
    for ips in ${CONTROLLER_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${CONTROLLER_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done
   
    for ips in ${CONTROLLER_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
elif [[ $1 = "compute" ]];then 
    #for compute nodes
    for ips in ${COMPUTE_NODE_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${COMPUTE_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done
 
    for ips in ${COMPUTE_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
elif [[ $1 = "network" ]];then 
    #for network nodes
    for ips in ${NETWORK_NODE_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${NETWORK_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done

    for ips in ${NETWORK_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
fi
}

function zabbix_agent_deploy(){
local METADATA
METADATA=compute    #change this for your request
echo $BLUE Beginning install zabbix agent on $YELLOW $METADATA  $NO_COLOR
cat ./$METADATA | while read ips ; do scp -r install-zabbix-agent/ $ips:/root/; debug $? ; done  1>/dev/null 2>&1

cat ./$METADATA | while read ips ; do ssh -n $ips /bin/bash /root/install-zabbix-agent/install-agent.sh \
$SERVERIP $METADATA ;debug $? ;done  2>/dev/null

cat ./$METADATA | while read ips ; do ssh -n $ips 'rm -rf /root/install-zabbix-agent/';done
echo $GREEN Finished install zabbix agent on host: $YELLOW  $(cat ./$METADATA) $NO_COLOR
}

cat 1>&2 <<__EOF__
$MAGENTA===============================================================================
            Thanks you use this script to deploy openstack !
                         Author: Kean Lee
                This script provide the below option:          
===============================================================================
$NO_COLOR
__EOF__

PS3="$BLUE Please Select a Number To Execute: $NO_COLOR"
export PS3
select OPTION in ${option[*]};do
    break
done
    case $OPTION in
        deploy-controller-node)
            controller
	    ;;
        galera-cluster)
            controller galera
            ;;
        deploy-compute-node)
            compute
  	    ;;
        deploy-network-node)
            network_node
	    ;;
        deploy-all)
            controller
            network_node
            compute
            ;;
        check-controller)
            check_info controller 
            ;;
        check-compute)
            check_info compute
	    ;;
        check-network)
            check_info network
            ;;
        check-all)
            check_info controller
            check_info network
            check_info compute    
            ;;
        deploy-controller-as-network-node)
            controller  controller-as-network-node
	    ;;
        deploy-compute-as-network-node)
            compute  compute-as-network-node
	    ;;
        ssh-key-compute)
            ssh_key compute
 	    ;;
	ssh-key-controller)
            ssh_key controller
	    ;;
	ssh-key-network)
            ssh_key network 
            ;;
	ssh-key-all)
            ssh_key controller
            ssh_key network
            ssh_key compute
            ;;
	help)
            help
            ;;
        exit)
            echo $GREEN =========== GoodBye !!! =========== $NO_COLOR
            ;;
        *)
            echo $RED Your imput is Invalid Option, Try another one option that is listed above . $NO_COLOR
  esac
