#!/bin/bash
#author by keanlee on May 15th of 2017 

cd $(cd $(dirname $0); pwd)
# ansi colors for formatting heredoc
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

source ./VARIABLE 

README=$(cat ./README.txt)
echo $GREEN $README $NO_COLOR 

help(){
echo $RED --------Usage as below ---------  $NO_COLOR    
    echo  $BLUE sh $0 install controller $NO_COLOR  
    echo  $BLUE sh $0 install ha_proxy  $NO_COLOR
    echo  $BLUE sh $0 install compute   $NO_COLOR
 
}

if [[ $# = 0 || $# -gt 1 ]]; then 
help
fi

debug(){
if [[ $1 -ne 0 ]]; then 
echo $RED Faild install package, please check your yum repos $NO_COLOR 
exit 1
fi
}




