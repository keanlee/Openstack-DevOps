#!/bin/bash 

function ntp(){

yum install ntp -y  1>/dev/null
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate $NTP_SERVER_IP 1>/dev/null
hwclock --systohc
sed -i "/server 0.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "/server 1.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "/server 2.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "/server 3.centos.pool.ntp.org iburst/d" /etc/ntp.conf
sed -i "21 i server $NTP_SERVER_IP iburst " /etc/ntp.conf
systemctl enable ntpd.service 1>/dev/null && 
systemctl start ntpd.service
}


