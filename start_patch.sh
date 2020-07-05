#!/bin/bash

# Script Name: start_patch.sh 
# Description: This script will start the patching by creating screen session for the server and executed auto_patch.sh script
# Author: shamril@my.ibm.com
# Date: 28th June 2020

DATE=$(date +"%Y%m%d-%H%M%S")
LOG_FILE=/tmp/$1-start_patch-$DATE.log
LOG_FILE2=/tmp/$1-auto_patch-$DATE.log

# Change the username accrodingly
#USER=osadmin
USER=iinstall
#USER=ami

# Color codes
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;93m'
GREEN='\033[0;92m'
NC='\033[0m' # No Color

SCREEN_ID=$1_$DATE

usage(){
        echo -e "Usage: ${RED}$0 <server name/ip address>${NC}"
        exit 1
}

patch_success()
{       
        echo -e "PATCHING STATUS: ${GREEN}SUCCESS${NC}"
}

patch_fail()
{
        echo -e "${RED}*** Please check. Aborting...${NC}"
        echo -e "PATCHING STATUS: ${RED}FAILED${NC}"
        exit 1
}
 
[[ $# -eq 0 ]] && usage

echo "================================================================================"
echo ""

echo "=== Copying auto_patch.sh script to $1"
scp auto_patch.sh $USER@$1:/tmp/
if [[ $? -ne 0 ]]
then
    echo -e "${RED}*** scp auto_patch.sh script FAILED!${NC}"
    patch_fail
else
    echo "=== auto_patch.sh script successfully copied to $1"
fi

echo ""
echo "=== ssh to $1 and opening screen session for patching"
#ssh $USER@$1 screen -dmS $SCREEN_ID script -c /tmp/auto_patch.sh $LOG_FILE
ssh $USER@$1 'mv screenlog.0 screenlog.0.OLD > /dev/null 2>&1'
ssh $USER@$1 screen -L -dmS $SCREEN_ID /tmp/auto_patch.sh $1 $DATE 
if [[ $? -ne 0 ]]
then
    echo -e "${RED}*** ssh OR screen command FAILED!${NC}"
    patch_fail
else
    echo -e "=== DRY RUN Patching screen session ${BLUE}$SCREEN_ID${NC} is successfully running on ${BLUE}$1${NC}"
    echo ""
    echo -e "${YELLOW}ACTIONS REQUIRED:${NC}"
    echo -e "=== To PROCEED with the patching, please reattach to the patching screen session using this command: ${BLUE}ssh -t $USER@$1 screen -r $SCREEN_ID${NC}"
    echo -e "=== ${GREEN}NOTE: To detach from screen session use: Ctrl-a + Ctrl-d. DO NOT USE Ctrl-c${NC}"
    echo -e "=== ${GREEN}NOTE: If the screen session NO longer exist, please check log file below${NC}"
    echo -e "=== To view the patching log: ${BLUE}ssh $USER@$1 cat ${BLUE}$LOG_FILE2${NC}"
fi

echo ""
echo "================================================================================"
