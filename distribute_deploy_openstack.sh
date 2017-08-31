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
Help
Edit-env-variable
Config-repository
SSH-key-nodes
Check-nodes-system-info
Deploy-all
Deploy-controller-node
Deploy-compute-node
Deploy-block-node
Deploy-network-node
Deploy-galera-cluster
Exit
)

source ./deploy-openstack/bin/VARIABLE

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
           sh $0 Deploy-controller-node 
              $BLUE#To deploy controller/controller-as-network node$NO_COLOR 
             
           ${MAGENTA}sh $0 Deploy-compute-node
              $BLUE#To deploy compute/compute-as-network/compute-as-block node$NO_COLOR
             
           ${MAGENTA}sh $0 Deploy-network-node
              $BLUE#To deploy network node (single) $NO_COLOR
                    
           ${MAGENTA}sh $0 Deploy-all
              $BLUE#To deploy controller node,network node,compute node,block node$NO_COLOR
          
           ${MAGENTA}sh $0 Deploy-block-node
              $BLUE#To deploy block node (single)$NO_COLOR

           ${MAGENTA}sh $0 Check-nodes-system-info
              $BLUE#To check all node system info $NO_COLOR

           ${MAGENTA}sh $0 SSH-key-nodes
              $BLUE#Generating a new SSH key and adding it to the target hosts $NO_COLOR${MAGENTA}
==================================================================================
$NO_COLOR
__EOF__
}

function ssh_key(){
#make sure that all node can reachable from deploy host
for ips in ${CONTROLLER_IP[*]};do
    ping -c 1 ${ips} 1>/dev/null 2>&1
        debug "$?" "The ${YELLOW}$ips${RED} which belongs to CONTROLLER_IP is unreachable from Deploy Host"       
done 

for ips in ${COMPUTE_NODE_IP[*]};do
    ping -c 1 ${ips} 1>/dev/null 2>&1
        debug "$?" "The ${YELLOW}$ips${RED} which belongs to COMPUTE_NODE_IP is unreachable from Deploy Host"  
done

for ips in ${NETWORK_NODE_IP[*]};do
    ping -c 1 ${ips} 1>/dev/null 2>&1
        debug "$?" "The ${YELLOW}$ips${RED} which belongs to NETWORK_NODE_IP is unreachable from Deploy Host"
done

for ips in ${BLOCK_NODE_IP[*]};do
    ping -c 1 ${ips} 1>/dev/null 2>&1
        debug "$?" "The ${YELLOW}$ips${RED} which belongs to BLOCK_NODE_IP is unreachable from Deploy Host"
done

#do ssh-key to nodes
if [[ -e ~/.ssh/id_rsa.pub ]];then 
    rm -rf ~/.ssh/id_rsa*
fi
echo $BLUE Generating public/private rsa key pair $NO_COLOR
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa 1>/dev/null
#-N "" tells it to use an empty passphrase (the same as two of the enters in an interactive script)
#-f my.key tells it to store the key into my.key (change as you see fit).
 

which sshpass 1>/dev/null 2>&1 || rpm -ivh ./deploy-openstack/lib/sshpass* 1>/dev/null 2>&1   

echo -n $BLUE Please type the correct password for server:  $NO_COLOR
read Password

if [[ -e  ~/.ssh/known_hosts ]];then
    continue
else
    touch ~/.ssh/known_hosts
fi

if [[ ${#CONTROLLER_IP[*]} -ge 1 ]];then
    echo $BLUE copy public key to controller hosts: $NO_COLOR
    for ips in ${CONTROLLER_IP[*]};do
        if [[ $(cat ~/.ssh/known_hosts | grep $ips | wc -l) -ge 2 ]];then        
            sed -i "/${ips}/d" ~/.ssh/known_hosts
            ssh-keyscan $ips >> ~/.ssh/known_hosts 
        else
            ssh-keyscan $ips >> ~/.ssh/known_hosts
        fi
    done
    for ips in ${CONTROLLER_IP[*]};
        do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub $ips;
    done
fi

if [[ ${#COMPUTE_NODE_IP[*]} -ge 1 ]];then 
    echo $BLUE copy public key to compute hosts:  $NO_COLOR
    for ips in ${COMPUTE_NODE_IP[*]};do
        if [[ $(cat ~/.ssh/known_hosts | grep $ips | wc -l) -ge 2 ]];then 
            sed -i "/${ips}/d" ~/.ssh/known_hosts
            ssh-keyscan $ips >> ~/.ssh/known_hosts 
        else 
            ssh-keyscan $ips >> ~/.ssh/known_hosts
        fi
    done 
    for ips in ${COMPUTE_NODE_IP[*]};
        do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub  $ips;
    done 
fi

if [[ ${#NETWORK_NODE_IP[*]} -ge 1 ]];then
    echo $BLUE copy public key to network hosts:  $NO_COLOR
    for ips in ${NETWORK_NODE_IP[*]};do
        if [[ $(cat ~/.ssh/known_hosts | grep $ips | wc -l) -ge 2 ]];then        
            sed -i "/${ips}/d" ~/.ssh/known_hosts
            ssh-keyscan $ips >> ~/.ssh/known_hosts 
        else
            ssh-keyscan $ips >> ~/.ssh/known_hosts
        fi
    done 
    for ips in ${NETWORK_NODE_IP[*]};
        do sshpass -p $Password ssh-copy-id -i ~/.ssh/id_rsa.pub $ips;
    done
fi

if [[ ${#BLOCK_NODE_IP[*]} -ge 1 ]];then
    echo $BLUE copy public key to storage hosts:  $NO_COLOR
    for ips in ${BLOCK_NODE_IP[*]};do
        if [[ $(cat ~/.ssh/known_hosts | grep $ips | wc -l) -ge 2 ]];then        
            sed -i "/${ips}/d" ~/.ssh/known_hosts
            ssh-keyscan $ips >> ~/.ssh/known_hosts
        else
            ssh-keyscan $ips >> ~/.ssh/known_hosts 
        fi
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
elif [[ $1 = "block" ]];then
    local VALUE=deploy-block-node
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
if [[ ${#CONTROLLER_IP[*]} -ge 1 ]];then 
    #for controller nodes
    echo $MAGENTA  Check Controller/Galera Node System Info: $NO_COLOR
    for ips in ${CONTROLLER_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${CONTROLLER_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done
   
    for ips in ${CONTROLLER_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
fi

if [[ ${#COMPUTE_NODE_IP[*]} -ge 1 ]];then 
    #for compute nodes
    echo $MAGENTA  Check Compute Node System Info: $NO_COLOR
    for ips in ${COMPUTE_NODE_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${COMPUTE_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done
 
    for ips in ${COMPUTE_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
fi


if [[ ${#NETWORK_NODE_IP[*]} -ge 1 ]];then 
    #for network nodes
    echo $MAGENTA  Check Network Node System Info: $NO_COLOR
    for ips in ${NETWORK_NODE_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${NETWORK_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done

    for ips in ${NETWORK_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
fi

if [[ ${#BLOCK_NODE_IP[*]} -ge 1 ]];then
    #for block nodes
    echo $MAGENTA  Check Block Node System Info: $NO_COLOR
    for ips in ${BLOCK_NODE_IP[*]}; do scp ./deploy-openstack/bin/system_info.sh root@$ips:/home/; \
        debug "$?" "Failed scp deploy script to $ips host" ; done 1>/dev/null 2>&1
    for ips in ${BLOCK_NODE_IP[*]}; do ssh -n root@$ips /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$ips> error "; done

    for ips in ${BLOCK_NODE_IP[*]}; do ssh -n root@$ips 'rm -rf /home/system_info.sh';done
fi
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
        Deploy-controller-node)
            if [[ ${#CONTROLLER_IP[*]} -eq 3 ]] && [[ ${#CONTROLLER_HOSTNAME[*]} -eq 3 ]];then
                if [[ $(echo $CONTROLLER_VIP | awk -F "." '{print $1 $2 }') -eq $(echo ${CONTROLLER_IP[0]} | awk -F "." '{print $1 $2 }' ) ]];then
                    controller galera
                    controller
                else
                    debug "1" "The ${YELLOW}CONTROLLER_VIP${RED} must be a network segment with controller's ip"
                fi
            else 
                if [[ ${#CONTROLLER_IP[*]} -eq 1 ]] && [[ ${NETWORK_NODE_IP[0]} = ${CONTROLLER_IP[0]} ]];then 
                    controller  controller-as-network-node
                elif [[ ${#CONTROLLER_IP[*]} -eq 1 ]] && [[ ${NETWORK_NODE_IP[0]} != ${CONTROLLER_IP[0]} ]];then
                    controller
                elif [[ ${#NETWORK_NODE_IP[*]} -gt 1 ]];then 
                    debug "1" "The ${YELLOW}NETWORK_NODE_IP${RED} just support one right now (No HA right now)"
                else 
                    debug "1" "Deployer doesn't know how to deploy controller node,please check the variable "
                fi
            fi
            ;;
        Edit-env-variable)
            vim ./deploy-openstack/bin/VARIABLE 
            ;;
        Config-repository)
            vim ./deploy-openstack/repos/infinistack.repo   
           ;; 
        Deploy-galera-cluster)
            controller galera
            ;;
        Deploy-compute-node)
            if [[ ${#COMPUTE_NODE_IP[*]} -eq 1 ]] && [[ ${NETWORK_NODE_IP[0]} = ${COMPUTE_NODE_IP[0]} ]];then
                 compute  compute-as-network-node
                 if [[ ${#BLOCK_NODE_IP[*]} -eq 1 ]] && [[ ${COMPUTE_NODE_IP[0]} = ${BLOCK_NODE_IP[0]} ]];then 
                    compute block
                 fi 
            elif [[ ${NETWORK_NODE_IP[0]} != ${COMPUTE_NODE_IP[0]} ]] && [[ ${COMPUTE_NODE_IP[0]} = ${BLOCK_NODE_IP[0]} ]];then 
                compute 
                compute block 
            else
                compute
            fi 
  	    ;;
        Deploy-block-node)
            compute block
            ;;
        Deploy-network-node)
            network_node
	    ;;
        Deploy-all)
            controller
            network_node
            compute
            ;;
        Check-nodes-system-info)
            check_info 
            ;;
        SSH-key-nodes)
            ssh_key 
            ;;
	Help)
            help
            ;;
        Exit)
            echo $GREEN =========== GoodBye !!! =========== $NO_COLOR
            ;;
        *)
            echo $RED Your typed is Invalid Option, Try another one option that is listed above !!! $NO_COLOR
  esac
