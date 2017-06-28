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
which pv 1>/dev/null 2>&1 || rpm -ivh ./deploy-openstack/lib/pv* 1>/dev/null 2>&1
    debug "$?" "install pv failed "
echo -e $CYAN $(cat ./deploy-openstack/README.txt) $NO_COLOR | pv -qL 30
cat 1>&2 <<__EOF__
$MAGENTA========================================================================
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
              $BLUE#to check the controller node system info$NO_COLOR${MAGENTA}

           ${MAGENTA}sh $0 check-compute
              $BLUE#to check the compute node system info$NO_COLOR${MAGENTA}

           ${MAGENTA}sh $0 check-network
              $BLUE#to check the network node system info$NO_COLOR${MAGENTA}

           ${MAGENTA}sh $0 ssh-key-<target-hosts-role>
              $BLUE#to create ssh-key and copy it to tartget hosts 
            (target-hosts-role=controller,compute,network,storage)$NO_COLOR${MAGENTA}
========================================================================
$NO_COLOR
__EOF__
}

function ssh_key(){
echo $BLUE Generating public/private rsa key pair: $NO_COLOR
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
#-N "" tells it to use an empty passphrase (the same as two of the enters in an interactive script)
#-f my.key tells it to store the key into my.key (change as you see fit).

which sshpass 1>/dev/null 2>&1 || rpm -ivh ./deploy-openstack/lib/sshpass* 1>/dev/null 2>&1   

echo $BLUE Please type the correct password for all server:$NO_COLOR
read Password

if [[ $1 = "compute" ]];then 
echo $BLUE copy public key to compute hosts:  $NO_COLOR
for ips in $(cat ./deploy-openstack/hosts/COMPUTE_HOSTS);
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in $(cat ./deploy-openstack/hosts/COMPUTE_HOSTS);
    do sshpass -p $Password ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips
done 

elif [[ $1 = "controller" ]];then
echo $BLUE copy public key to controller hosts: $NO_COLOR
for ips in $(cat ./deploy-openstack/hosts/CONTROLLER_HOSTS);
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in $(cat ./deploy-openstack/hosts/CONTROLLER_HOSTS);
   do sshpass -p $Password ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
done

elif [[ $1 = "network" ]];then
echo $BLUE copy public key to network hosts:  $NO_COLOR
for ips in $(cat ./deploy-openstack/hosts/NETWORK_HOSTS);
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in $(cat ./deploy-openstack/hosts/NETWORK_HOSTS);
    do sshpass -p $Password ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
done

elif [[ $1 = "storage" ]];then
echo $BLUE copy public key to storage hosts:  $NO_COLOR
for ips in $(cat ./deploy-openstack/hosts/BLOCK_HOSTS);
    do ssh-keyscan $ips >> ~/.ssh/known_hosts ;
done 
for ips in $(cat ./deploy-openstack/hosts/BLOCK_HOSTS);
    do sshpass -p $Password ssh-copy-id -i /root/.ssh/id_rsa.pub  $ips;
done

fi
}



#----------------------------------controller node deploy ---------------------
function controller(){
echo $BLUE scp deploy script to target hosts $NO_COLOR 

cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do scp -r deploy-openstack/ \
$line:/home/; \
    debug "$?" "Failed scp deploy script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do ssh -n $line /bin/bash /home/deploy-openstack/install.sh \
controller | tee controller-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$line> error "; done

cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do ssh -n $line 'rm -rf /home/deploy-openstack/' ;done
}



#---------------------------------compute node deploy -----------------
function compute(){
echo $BLUE scp deploy script to target hosts $NO_COLOR 
cat ./deploy-openstack/hosts/COMPUTE_HOSTS | while read line ; do scp -r deploy-openstack/ $line:/home/; \
    debug "$?" "Failed scp deploy script to $line host" ; done 1>/dev/null 2>&1 

cat ./deploy-openstack/hosts/COMPUTE_HOSTS | while read line ; do ssh -n root@$line /bin/bash /home/deploy-openstack/install.sh \
compute | tee compute-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$line> error "; done

cat ./deploy-openstack/hosts/COMPUTE_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /home/deploy-openstack/';done

}




#-----------------------------show target host system info-------------------------------------
function check_info(){
#check the target host net and disk info
#for controller nodes
if [[ $1 = "controller" ]];then 
    cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do scp ./deploy-openstack/bin/system_info.sh root@$line:/home/; \
        debug "$?" "Failed scp deploy script to $line host" ; done 1>/dev/null 2>&1
    cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do ssh -n root@$line /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$line> error "; done
   
    cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /home/system_info.sh';done
elif [[ $1 = "compute" ]];then 
    #for compute nodes
    cat ./deploy-openstack/hosts/COMPUTE_HOSTS | while read line ; do scp ./deploy-openstack/bin/system_info.sh root@$line:/home/; \
        debug "$?" "Failed scp deploy script to $line host" ; done 1>/dev/null 2>&1
    cat ./deploy-openstack/hosts/COMPUTE_HOSTS | while read line ; do ssh -n root@$line /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$line> error "; done
 
    cat ./deploy-openstack/hosts/COMPUTE_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /home/system_info.sh';done
elif [[ $1 = "network" ]];then 
    #for network nodes
    cat ./deploy-openstack/hosts/NETWORK_HOSTS | while read line ; do scp ./deploy-openstack/bin/system_info.sh root@$line:/home/; \
        debug "$?" "Failed scp deploy script to $line host" ; done 1>/dev/null 2>&1
    cat ./deploy-openstack/hosts/NETWORK_HOSTS | while read line ; do ssh -n root@$line /bin/bash /home/system_info.sh; \
        debug "$?" "bash remote execute on remote host <$line> error "; done

    cat ./deploy-openstack/hosts/NETWORK_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /home/system_info.sh';done
fi
}



#----------------------------------network node deploy-----------------------
function network_node(){
echo $BLUE scp deploy script to target hosts $NO_COLOR 

cat ./deploy-openstack/hosts/NETWORK_HOSTS | while read line ; do scp -r deploy-openstack/ $line:/home/; \
    debug "$?" "Failed scp deploy script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/hosts/NETWORK_HOSTS | while read line ; do ssh -n root@$line /bin/bash /home/deploy-openstack/install.sh \
network | tee network-node-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log;done 

cat ./deploy-openstack/hosts/NETWORK_HOSTS | while read line ; do ssh -n root@$line 'rm -rf /home/deploy-openstack/' ;done 
}



#-----------------------------------controller as network node deploy---------------------
function controller_as_network_node(){
echo $BLUE scp deploy script to target hosts $NO_COLOR 

cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do scp -r deploy-openstack/ \
$line:/home/; \
    debug "$?" "Failed scp deplory script to $line host" ; done 1>/dev/null 2>&1

cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do ssh -n $line /bin/bash /home/deploy-openstack/install.sh \
controller-as-network-node | tee controller-network-$line-$(date "+%Y-%m-%d--%H:%M")-debug.log ; \
    debug "$?" "bash remote execute on remote host <$line> error "; done

cat ./deploy-openstack/hosts/CONTROLLER_HOSTS | while read line ; do ssh -n $line 'rm -rf /home/deploy-openstack/' ;done
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
check-network)
    check_info network
    ;;
controller-as-network-node)
    controller_as_network_node
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
*)
   help
esac
