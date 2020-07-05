#!/bin/bash

# Script Name: auto_patch.sh 
# Description: This script will be called by start_patch.sh script and will perform automatic patching
# Author: shamril@my.ibm.com
# Date: 28th June 2020

SERVER_IP=$1
DATE=$2
HOSTNAME=`uname -n`
LOG_FILE=/tmp/$SERVER_IP-auto_patch-$DATE.log
PATCH_STATUS_LOG=/tmp/$SERVER_IP-auto_patch_status-$DATE.log

# Color codes
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;93m'
MAGENTA='\033[0;35m'
GREEN='\033[0;92m'
BLINK='\033[0;5m'
NC='\033[0m' # No Color

DATE_START=$(date +"%Y%m%d-%H%M%S")

# Change the repo accordingly
REPO=OEL_Q3

DRYRUN_COMMAND="sudo yum --disablerepo=* --enablerepo=$REPO --setopt tsflags=test update -y"
#DRYRUN_COMMAND="sudo yum --setopt tsflags=test update -y"

PATCH_COMMAND="sudo yum --disablerepo=* --enablerepo=$REPO update -y"
#PATCH_COMMAND="sudo yum update -y"

patch_success()
{
	echo -e "=== PATCHING STATUS: ${GREEN}SUCCESS${NC}"
	PATCH_STATUS=success
}

patch_fail()
{
	echo -e "*** PATCHING STATUS: ${RED}FAILED${NC}"
	echo -e "*** ${RED}Please check. Aborting...${NC}"
	PATCH_STATUS=fail
}

save_log()
{
	echo ""
	echo "=== Saving the log..."
	echo -e "=== Patching log is at ${BLUE}$SERVER_IP${NC} in ${BLUE}$LOG_FILE${NC}"
	sleep 20
	cp -p screenlog.0 $LOG_FILE
}

proceed_reboot()
{
	echo "=== uname -a"
	uname -a
	echo -e "=== ${YELLOW}Reboot $HOSTNAME ($SERVER_IP)? [y/n]${NC}"
	read REBOOT_ANSWER
	if [[ $REBOOT_ANSWER == "y" ]] || [[ $REBOOT_ANSWER == "Y" ]]
	then
            echo "=== Answer is $REBOOT_ANSWER. Proceed with reboot..."
	    echo -e "=== ${BLINK}Rebooting $HOSTNAME ($SERVER_IP) in 30 seconds...${NC}"
	    sleep 10
    	    save_log
    	    echo "=== Patching success. REBOOTED. Date: `date`" > $PATCH_STATUS_LOG
	    sudo reboot
            exit
        else
            echo -e "*** ${RED}Answer is $REBOOT_ANSWER. Not reboot.${NC}"
    	    echo "=== Patching success. NOT REBOOTED. Date: `date`" > $PATCH_STATUS_LOG
	    echo -e "=== ${GREEN}$HOSTNAME ($SERVER_IP) NOT REBOOTED${NC}"
    	    save_log
	    exit 1
	fi
}

echo "=== Patching started on `date`"

echo "=== Starting DRY RUN patch..."
echo -e "=== ${BLUE}$DRYRUN_COMMAND${NC}"
$DRYRUN_COMMAND

# Check whether the dry run was successful
if [[ $? -eq 0 ]]
then
    echo -e "=== DRY RUN patch is ${GREEN}OK${NC}\n"
    echo -e "=== ${BLUE}$PATCH_COMMAND${NC}"
    echo -e "=== ${YELLOW}Proceed with the patching (above command)? [y/n]${NC}"
    read ANSWER
    #ANSWER=y
    if [[ $ANSWER == "y" ]] || [[ $ANSWER == "Y" ]]
    then
        echo "=== Answer is $ANSWER. Proceed with patch installation..."
        echo ""
        echo "=== Current OS Version:"
        uname -a
        cat /etc/redhat-release
        echo ""
        echo "=== Installing the patches..."
        $PATCH_COMMAND
        if [[ $? -eq 0 ]]
        then
            echo -e "=== Patches ${GREEN}SUCCESSFULLY${NC} installed"
            echo ""
	    echo "=== Verifying the new kernel..."
            NEW_KERNEL=`sudo yum list installed kernel | tail -1 | awk '{print $2}'`
            #NEW_KERNEL=3.10.0-1062.12.1.el7	# test with old kernel
	    echo -e "=== New installed kernel version: ${BLUE}$NEW_KERNEL${NC}"
            sudo grep $NEW_KERNEL /boot/grub2/grubenv && sudo grep $NEW_KERNEL /boot/grub2/grub.cfg
            if [[ $? -eq 0 ]]
	    then
	       echo -e "=== New kernel is SET as ${GREEN}DEFAULT${NC}"
               echo "=== Patching completed on `date`"
               echo ""
               patch_success
            else
               echo -e "*** ${RED}New kernel is NOT SET as DEFAULT${NC}"
               patch_fail
            fi
	else
	    echo "*** ${RED}Patches NOT successfully installed${NC}"    
	    patch_fail
	fi
    else
        echo -e "*** ${RED}Answer is $ANSWER${NC}"
        patch_fail
    fi
else
    echo -e "*** ${RED}DRY RUN patch is NOT OK!${NC}"
    patch_fail
fi

DATE_END=$(date +"%Y%m%d-%H%M%S")
echo ""
echo "=== auto_patch.sh script completed on `date`"
echo ""

if [[ "$PATCH_STATUS" == "success" ]]
then
    # Reboot
    proceed_reboot
else
    # No reboot
    echo "*** Patching failed. NOT REBOOTED. Date: `date`" > $PATCH_STATUS_LOG
    save_log
    exit 1
fi
