#!/bin/bash

# Script Name: s.sh
# Description: This script will check the VPN connection and ssh passwordless connection for the server and particular users, and then ssh into the server
# Author: shamril@my.ibm.com
# Date: 17th July 2020

#NOW=$(date +"%d-%B-%y"_"%H:%M:%S")
NOW=$(date +"%Y%m%d-%H%M%S")
SSH="ssh -o BatchMode=yes -o ConnectTimeout=5 -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ServerAliveInterval=120"
SSH1="ssh -n -q -o BatchMode=yes -o ConnectTimeout=5 -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ServerAliveInterval=120"
SSH2="ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o ServerAliveInterval=120"
CMS_USER_SERVERS=/home/ami/T430/Documents/IBM/Clients/CMAS/CMS_USER_SERVERS.txt
CMS_USER_SERVERS_UNIQ=/home/ami/T430/Documents/IBM/Clients/CMAS/CMS_USER_SERVERS_UNIQ.txt

# Color codes
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;93m'
MAGENTA='\033[0;35m'
GREEN='\033[0;92m'
BLINK='\033[0;5m'
NC='\033[0m' # No Color

usage(){
        echo "Usage: $0 <servername/IP address>"
        exit 1
}

[[ $# -eq 0 ]] && usage

#s="`echo $1 | tr '[:upper:]' '[:lower:]'`"

sort $CMS_USER_SERVERS | uniq > $CMS_USER_SERVERS_UNIQ 2> /dev/null

# Check whether VPN is connected
nc -zw 5 $1 22
if [[ $? == 0 ]]
then
  grep -q $1 $CMS_USER_SERVERS_UNIQ 
  if [[ $? == 0 ]]; then
    NOW=$(date +"%Y%m%d-%H%M%S")
    USER=$(grep $1 $CMS_USER_SERVERS_UNIQ | awk '{print $1}')
    echo -e "=== ${BLUE}$NOW: passwordless authentication was OK for $1 with user $USER${NC}"
    SSH_STATUS=OK
  else  
    echo "=== $NOW: Checking ssh passwordless authenthication. Please wait..."
    for USER in oralls osadmin ibmadmin iinstall
      do
      $SSH $USER@$1 '/bin/true' 2> /dev/null
      if [[ $? == 0 ]]
      then
          NOW=$(date +"%Y%m%d-%H%M%S")
          echo -e "=== ${BLUE}$NOW: ssh passwordless authentication is OK for $1 with user $USER${NC}"
	  echo "$USER $1" >> $CMS_USER_SERVERS
          SSH_STATUS=OK
          break
      else
          SSH_STATUS=KO
      fi 
    done
  fi
else
  NOW=$(date +"%Y%m%d-%H%M%S")
  echo -e "=== ${RED}$NOW: Please check whether VPN is connected!!!${NC}"
  echo ""
  exit 1
fi

if [[ $SSH_STATUS == "OK" ]]
then
    if [[ $2 == "" ]]; then
      NOW=$(date +"%Y%m%d-%H%M%S")
      echo "=== $NOW: $SSH $USER@$1"
      echo ""
      $SSH $USER@$1
    else
      NOW=$(date +"%Y%m%d-%H%M%S")
      echo "=== $NOW: $SSH1 $USER@$1 $2"
      echo ""
      $SSH1 $USER@$1 $2
    fi
else
    NOW=$(date +"%Y%m%d-%H%M%S")
    echo -e "=== ${RED}$NOW: ssh passwordless authentication is KO!!!${NC}"
    echo ""
    NOW=$(date +"%Y%m%d-%H%M%S")
    echo "=== $NOW: $SSH2 oralls@$1"
    echo ""
    $SSH2 oralls@$1
    exit 1
fi

sort $CMS_USER_SERVERS | uniq > $CMS_USER_SERVERS_UNIQ 2> /dev/null
