#!/bin/bash

# Script Name: account_expiry_report.sh
# Description: This script will collect all accounts' expiry details on Linux server and compile into single csv format file
# and email the csv file to respective email address.
# Author: shamril@my.ibm.com
# Date: 28th Jan 2021

YELLOW='\033[0;93m'
BLUE='\033[0;34m'
GREEN='\033[0;92m'
NC='\033[0m' # No Color
TODAY_DATE=$(date +"%Y%m%d")
SINGLE_USER=/tmp/single_user.txt
ACCOUNT_REPORT=./$TODAY_DATE-`hostname`-account_expiry_report.csv
> $ACCOUNT_REPORT
> $SINGLE_USER

check_user() {
# Groups
group=`id -nG $user`

# Password Expires
expires=`sudo chage -l $user | grep  'Password expires' | cut -d':' -f2 | sed 's/,//g'`

# Last Password changed
changed=`sudo chage -l $user | grep  'Last password change' | cut -d':' -f2 | sed 's/,//g'`

# Maximum number of days between password change
maximum=`sudo chage -l $user | grep  'Maximum number of days between password change' | cut -d':' -f2`

echo "$user," > $SINGLE_USER
echo "$group," >> $SINGLE_USER
echo "$expires," >> $SINGLE_USER
echo "$changed," >> $SINGLE_USER
echo "$maximum," >> $SINGLE_USER

# Account Locked
LOCKED=`sudo pam_tally2 --user=$user | grep $user | awk '{print $2}'`
if [[ $LOCKED -ge 3 ]]
then
   ACCOUNT_LOCKED="YES"
else
   ACCOUNT_LOCKED="NO"
fi
echo $ACCOUNT_LOCKED >> $SINGLE_USER

while read line
do
    echo -n "$line"
done < $SINGLE_USER >> $ACCOUNT_REPORT
echo " " >> $ACCOUNT_REPORT
}

spin() {
    sp='/-\|'
    printf ' '
    while true; do
        printf '\b%.1s' "$sp"
        sp=${sp#?}${sp%???}
        sleep 0.05
    done
}

spin &
pid=$!

for user in `awk -F':' '{ print $1}' /etc/passwd`
do
   check_user
done

# Add tittle on top
sed -i '1s/^/User,Groups,Password Expires,Last Password changed,Maximum number of days between password change,Account Locked\n/' $ACCOUNT_REPORT

# Email the report
EMAIL_ADDRESS=shamril@my.ibm.com
echo "The CSV file as attached generated on $TODAY_DATE" | mail -s "Account Expiry report for `hostname`" -a $ACCOUNT_REPORT $EMAIL_ADDRESS

echo " "
echo -e "Account Expiry report COMPLETED for ${BLUE}`hostname`${NC} on `date`"
echo -e "CSV file generated at ${BLUE}$ACCOUNT_REPORT${NC}"

# Kill the spinner task
kill $pid > /dev/null 2>&1
