#!/usr/bin/bash

DATE_NOW=$(date +"%Y%m%d-%H%M%S")
OUTPUT_TXT=/tmp/health_check_report_$(hostname -f)_$DATE_NOW.txt
OUTPUT_CSV=/tmp/health_check_report_$(hostname -f)_$DATE_NOW.csv
S="************************************"
D="-------------------------------------"
COLOR="y"

echo -e "$D$D"
echo "Health Check started on `date`"

health_check1()
{

#MOUNT=$(mount|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|grep -v "loop"|sort -u -t' ' -k1,2)
MOUNT=$(mount|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs|nfs|cifs"|grep -v "loop"|sort -u -t' ' -k1,2)
FS_USAGE=$(df -PThl -x tmpfs -x iso9660 -x devtmpfs -x squashfs|awk '!seen[$1]++'|sort -k6n|tail -n +2)
IUSAGE=$(df -iPThl -x tmpfs -x iso9660 -x devtmpfs -x squashfs|awk '!seen[$1]++'|sort -k6n|tail -n +2)

if [ $COLOR == y ]; then
{
 GCOLOR="\e[47;32m ------ OK/HEALTHY \e[0m"
 WCOLOR="\e[43;31m ------ WARNING \e[0m"
 CCOLOR="\e[47;31m ------ CRITICAL \e[0m"
}
else
{
 GCOLOR=" ------ OK/HEALTHY "
 WCOLOR=" ------ WARNING "
 CCOLOR=" ------ CRITICAL "
}
fi

echo -e "$S"
echo -e "\tSystem Health Status"
echo -e "$S"

#--------Print Operating System Details--------#
hostname -f &> /dev/null && printf "Hostname : $(hostname -f)" || printf "Hostname : $(hostname -s)"

echo -en "\nOperating System : "
[ -f /etc/os-release ] && echo $(egrep -w "NAME|VERSION" /etc/os-release|awk -F= '{ print $2 }'|sed 's/"//g') || cat /etc/system-release

echo -e "Kernel Version :" $(uname -r)
printf "OS Architecture :"$(arch | grep x86_64 &> /dev/null) && printf " 64 Bit OS\n"  || printf " 32 Bit OS\n"

#--------Print system uptime-------#
UPTIME=$(uptime)
echo -en "System Uptime : "
echo $UPTIME|grep day &> /dev/null
if [ $? != 0 ]; then
  echo $UPTIME|grep -w min &> /dev/null && echo -en "$(echo $UPTIME|awk '{print $2" by "$3}'|sed -e 's/,.*//g') minutes" \
 || echo -en "$(echo $UPTIME|awk '{print $2" by "$3" "$4}'|sed -e 's/,.*//g') hours"
else
  echo -en $(echo $UPTIME|awk '{print $2" by "$3" "$4" "$5" hours"}'|sed -e 's/,//g')
fi
echo -e "\nCurrent System Date & Time : "$(date +%c)

} > $OUTPUT_TXT

health_check2()
{

#--------Check for any read-only file systems--------#
echo -e "\nChecking For Read-only File System[s]"
echo -e "$D"
echo "$MOUNT"|grep -w \(ro\) && echo -e "\n.....Read Only file system[s] found"|| echo -e ".....No read-only file system[s] found. "

#--------Check for currently mounted file systems--------#
echo -e "\n\nChecking For Currently Mounted File System[s]"
echo -e "$D$D"
echo "$MOUNT"|column -t

} >> $OUTPUT_TXT

health_check3()
{

#--------Check disk usage on all mounted file systems--------#
echo -e "\n\nChecking For Disk Usage On Mounted File System[s]"
echo -e "$D$D"
echo -e "( 0-85% = OK/HEALTHY,  85-95% = WARNING,  95-100% = CRITICAL )"
echo -e "$D$D"
echo -e "Mounted File System[s] Utilization (Percentage Used):\n"

COL1=$(echo "$FS_USAGE"|awk '{print $1 " "$7}')
COL2=$(echo "$FS_USAGE"|awk '{print $6}'|sed -e 's/%//g')

for i in $(echo "$COL2"); do
{
  if [ $i -ge 95 ]; then
    COL3="$(echo -e $i"% $CCOLOR\n$COL3")"
    FS_STATUS="KO"
  elif [[ $i -ge 85 && $i -lt 95 ]]; then
    COL3="$(echo -e $i"% $WCOLOR\n$COL3")"
    FS_STATUS="KO"
  else
    COL3="$(echo -e $i"% $GCOLOR\n$COL3")"
    FS_STATUS="OK"
  fi
}
done
COL3=$(echo "$COL3"|sort -k1n)
paste  <(echo "$COL1") <(echo "$COL3") -d' '|column -t

#--------Check for any zombie processes--------#
echo -e "\n\nChecking For Zombie Processes"
echo -e "$D"
ps -eo stat|grep -w Z 1>&2 > /dev/null
if [ $? == 0 ]; then
  echo -e "Number of zombie process on the system are :" $(ps -eo stat|grep -w Z|wc -l)
  echo -e "\n  Details of each zombie processes found   "
  echo -e "  $D"
  ZPROC=$(ps -eo stat,pid|grep -w Z|awk '{print $2}')
  for i in $(echo "$ZPROC"); do
      ps -o pid,ppid,user,stat,args -p $i
  done
else
 echo -e "No zombie processes found on the system."
fi

} >> $OUTPUT_TXT

health_check4()
{

#--------Check Inode usage--------#
echo -e "\n\nChecking For INode Usage"
echo -e "$D$D"
echo -e "( 0-85% = OK/HEALTHY,  85-95% = WARNING,  95-100% = CRITICAL )"
echo -e "$D$D"
echo -e "INode Utilization (Percentage Used):\n"

COL11=$(echo "$IUSAGE"|awk '{print $1" "$7}')
COL22=$(echo "$IUSAGE"|awk '{print $6}'|sed -e 's/%//g')

for i in $(echo "$COL22"); do
{
  if [[ $i = *[[:digit:]]* ]]; then
  {
  if [ $i -ge 95 ]; then
    COL33="$(echo -e $i"% $CCOLOR\n$COL33")"
    INODE_STATUS="KO"
  elif [[ $i -ge 85 && $i -lt 95 ]]; then
    COL33="$(echo -e $i"% $WCOLOR\n$COL33")"
    INODE_STATUS="KO"
  else
    COL33="$(echo -e $i"% $GCOLOR\n$COL33")"
    INODE_STATUS="OK"
  fi
  }
  else
    COL33="$(echo -e $i"% (Inode Percentage details not available)\n$COL33")"
  fi
}
done

COL33=$(echo "$COL33"|sort -k1n)
paste  <(echo "$COL11") <(echo "$COL33") -d' '|column -t

#--------Check for SWAP Utilization--------#
echo -e "\n\nChecking SWAP Details"
echo -e "$D"
echo -e "Total Swap Memory in MiB : "$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024}')", in GiB : "\
$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024/1024}')
echo -e "Swap Free Memory in MiB : "$(grep -w SwapFree /proc/meminfo|awk '{print $2/1024}')", in GiB : "\
$(grep -w SwapFree /proc/meminfo|awk '{print $2/1024/1024}')

} >> $OUTPUT_TXT

health_check5()
{

#--------Check for Processor Utilization (current data)--------#
echo -e "\n\nChecking For Processor Utilization"
echo -e "$D"
echo -e "\nCurrent Processor Utilization Summary :\n"
#mpstat|tail -2
sar 5 2
echo -e "$D$D"
echo -e "( 0-80% = OK/HEALTHY,  80-100% = CRITICAL )"
echo -e "$D$D"
CPU_THRESHOLD=80.00
CPU_LOAD=`sar -P ALL 5 5 |grep 'Average.*all' |awk -F" " '{print 100.0 -$NF}'`
if [[ $CPU_LOAD > $CPU_THRESHOLD ]]
then
    echo -e "Current CPU LOAD is $CPU_LOAD $CCOLOR\n"
    echo "The CPU LOAD has reached $CPU_LOAD"
    CPU_STATUS="KO"
else
    echo -e "Current CPU LOAD is $CPU_LOAD $GCOLOR\n"
    CPU_STATUS="OK"
fi

#--------Check for Memory Utilization (current data)--------#
echo -e "\n\nChecking For Memory Utilization"
echo -e "$D"
echo -e "\nCurrent Memory Utilization Summary :\n"
free
echo -e "$D$D"
echo -e "( 0-85% = OK/HEALTHY,  85-100% = CRITICAL )"
echo -e "$D$D"
MEM_THRESHOLD=85.00
MEM_LOAD=`free | awk '/Mem/{printf("RAM Usage: %.2f\n"), $3/$2*100}' |  awk '{print $3}'`
if [[ $MEM_LOAD > $MEM_THRESHOLD ]]
then
    echo -e "Current Memory usage is $MEM_LOAD $CCOLOR\n"
    echo "The Memory usage has reached $MEM_LOAD"
    MEM_STATUS="KO"
else
    echo -e "Current Memory usage is $MEM_LOAD $GCOLOR\n"
    MEM_STATUS="OK"
fi

} >> $OUTPUT_TXT

health_check6()
{

#--------Check for load average (current data)--------#
echo -e "\n\nChecking For Load Average"
echo -e "$D"
echo -e "Current Load Average : $(uptime|grep -o "load average.*"|awk '{print $3" " $4" " $5}')"

echo -e "$D$D"
echo -e "( 0-20 = OK/HEALTHY,  20 above = CRITICAL )"
echo -e "$D$D"
tsleep=10 # time to wait before 2 checks
llimit=20 # load limit before action

load=`cat /proc/loadavg |awk {'print $1'}|cut -d "." -f1` # The load average now
sleep $tsleep
load2=`cat /proc/loadavg |awk {'print $1'}|cut -d "." -f1` # The load average after tsleep

if test "$load" -ge $llimit
then
    if test "$load2" -ge $load
    then
        date=`date`
        echo -e "Current Load Average is $load2 $CCOLOR\n"
        echo "The Load Average has reached $load1 and $load2"
        LOAD_STATUS="KO"
    else
        echo -e "Current Load Average is $load $GCOLOR\n"
        LOAD_STATUS="KO"
    fi
else
    echo -e "Current Load Average is $load $GCOLOR\n"
    LOAD_STATUS="OK"
fi

} >> $OUTPUT_TXT

health_check7()
{

#------Print most recent 3 reboot events if available----#
echo -e "\n\nMost Recent 3 Reboot Events"
echo -e "$D$D"
last -x 2> /dev/null|grep reboot 1> /dev/null && /usr/bin/last -x 2> /dev/null|grep reboot|head -3 || \
echo -e "No reboot events are recorded."

#------Print most recent 3 shutdown events if available-----#
echo -e "\n\nMost Recent 3 Shutdown Events"
echo -e "$D$D"
last -x 2> /dev/null|grep shutdown 1> /dev/null && /usr/bin/last -x 2> /dev/null|grep shutdown|head -3 || \
echo -e "No shutdown events are recorded."

#--------Print top 5 Memory & CPU consumed process threads---------#
#--------excludes current running program which is hwlist----------#
echo -e "\n\nTop 5 Memory Resource Hog Processes"
echo -e "$D$D"
ps -eo pmem,pid,ppid,user,stat,args --sort=-pmem|grep -v $$|head -6|sed 's/$/\n/'

echo -e "\nTop 5 CPU Resource Hog Processes"
echo -e "$D$D"
ps -eo pcpu,pid,ppid,user,stat,args --sort=-pcpu|grep -v $$|head -6|sed 's/$/\n/'

echo -e "\nIOSTAT 2 outputs in 5 seconds interval"
echo -e "$D$D"
#iostat -mhxNt 5 5
iostat -mhxNt 5 2

echo -e "\nVMSTAT 2 outputs in 5 seconds interval"
echo -e "$D$D"
#vmstat -S M 5 5 -t
vmstat -S M 5 2 -t

} >> $OUTPUT_TXT

health_check1
echo -ne '[#####                              ](15%)\r'
sleep 1
health_check2
echo -ne '[##########                         ](30%)\r'
sleep 1
health_check3
echo -ne '[###############                    ](45%)\r'
sleep 1
health_check4
echo -ne '[####################               ](60%)\r'
sleep 1
health_check5
echo -ne '[#########################          ](75%)\r'
sleep 1
health_check6
echo -ne '[##############################     ](90%)\r'
sleep 1
health_check7
echo -ne '[###################################](100%)\r'
echo -ne '\n'
sleep 1

echo ""
echo "Health Check completed on `date`"
echo "Health Check report available in $OUTPUT_TXT"
echo -e "$D$D"
echo "Health Check STATUS summary"
echo -e "$D$D"
echo "Hostname, Filesystem, Inode, CPU, Memory, Load Average"
echo "$(hostname -f), $FS_STATUS, $INODE_STATUS, $CPU_STATUS, $MEM_STATUS, $LOAD_STATUS"
echo "Health Check status summary available in $OUTPUT_CSV"
echo "Hostname, Filesystem, Inode, CPU, Memory, Load Average" > $OUTPUT_CSV
echo "$(hostname -f), $FS_STATUS, $INODE_STATUS, $CPU_STATUS, $MEM_STATUS, $LOAD_STATUS" >> $OUTPUT_CSV
echo -e "$D$D"
