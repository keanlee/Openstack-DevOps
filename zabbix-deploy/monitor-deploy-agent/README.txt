     -------安装注意事项--------
前提条件：该脚本适合在能免秘钥登录所有node（节点）的机器上执行
1.将要安装的compute节点，controller节点分别列在对应的文件中,对应为Host metadata
2.在install.sh中 主要完成scp install-zabbix-agent 到所有的node上和远程在各个node上执行install-agent.sh 功能
     --------NOTICE------------
Precondition:This script can be execute on one node which is can no password to login all node 
1.Please list the ip of controller and compute node into controller file and compute file (Host Metadata)
2.This script function is just scp install-zabbix-agent to target host and remote execute the install zabbix agent script 
