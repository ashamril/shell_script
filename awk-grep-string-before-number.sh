# output in multiple lines
#awk -F-[*0-9] '{print $1}' $1



# output in single line w |
echo "rpm -qa | egrep -i '`awk -F-[*0-9] '{print "^"$1"-"}' $1 | sort | uniq | paste -d\| -s`' | sort"
echo " "
# output in single line w space
echo "yum update `awk -F-[*0-9] '{print $1}' $1 | sort | uniq | paste -d" " -s` -y" 
