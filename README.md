#  Openstack

## This Repository can help you  deploy: 
  ###                  Deploy  openstack you can follow belowi:

`==================================================================================
              --------Usage as below ---------
           sh distribute_deploy_openstack.sh deploy-controller-node 
              #to deploy controller node 
             
           sh distribute_deploy_openstack.sh deploy-compute-node
              #to deploy compute node
             
           sh distribute_deploy_openstack.sh deploy-network-node
              #to deploy network node
                    
           sh distribute_deploy_openstack.sh deploy-all
              #to deploy controller node ,network node,compute node

           sh distribute_deploy_openstack.sh deploy-controller-as-network-node
              #to deploy controller as network node  
           
           sh distribute_deploy_openstack.sh deploy-compute-as-network-node
              #to deploy compute as network node

           sh distribute_deploy_openstack.sh check-controller 
              #to check the controller node system info

           sh distribute_deploy_openstack.sh check-compute
              #to check the compute node system info

           sh distribute_deploy_openstack.sh check-network
              #to check the network node system info
          
           sh distribute_deploy_openstack.sh check-all
              #to check all node system info 

           sh distribute_deploy_openstack.sh ssh-key-<target-hosts-role>
              #to create ssh-key and copy it to target hosts 
            (target-hosts-role=controller,compute,network,storage,all)
==================================================================================`



  ###                   Zabbix 
  ###                   ceph 
