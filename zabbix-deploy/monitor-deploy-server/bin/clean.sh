#!/bin/bash
echo -e "\e[1;31m Your OS current installed zabbix server: $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') \e[0m"
       note=$(echo -e "\e[1;31m Do you want delete you current installed zabbix server: $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') \e[0m")
       read -p "$note yes or no: " choice
       function choose(){
       case $1 in
       yes)
           echo -e "\e[1;31m Begin clean installed env... \e[0m"
           yum erase -y zabbix-server-mysql 1>/dev/null 2>&1
           yum erase -y zabbix-web-mysql 1>/dev/null 2>&1
           yum erase -y mariadb-server 1>/dev/null 2>&1
           yum erase -y zabbix-get  1>/dev/null 2>&1
           yum erase -y zabbix-agent 1>/dev/null 2>&1
           yum erase -y  mariadb-server mariadb mariadb-libs 1>/dev/null 2>&1
           yum erase -y zabbix-release 1>/dev/null 2>&1
           yum erase -y  httpd httpd-tools 1>/dev/null 2>&1
           yum erase -y  zabbix-sender 1>/dev/null 2>&1
           rm -rf /var/lib/mysql
           rm -rf /usr/lib64/mysql
           rm -rf /etc/my.cnf
           #rm -f /etc/yum.repos.d/*
           yum clean all   1>/dev/null 2>&1
           rm -rf /etc/httpd
           rm -rf /etc/zabbix/
           echo -e "\e[1;32m Finshed clean installed env \e[0m"
           ;;
       no)
           echo -e "\e[1;34m You didn't delete zabbix server \e[0m "
           exit 0
       esac 
}
choose $choice

