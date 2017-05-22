#!/bin/bash 
yum install -y ceph-deploy  ntp ntpdate ntp-doc   openssh-server 

USER=admin
useradd -d /home/$USER -m $USER


passwd $USER

echo "$USER ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER

sudo chmod 0440 /etc/sudoers.d/$USER

ssh-keygen

setenforce 0

 
