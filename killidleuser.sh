#for user in `w -h | grep pts | awk '{print $2}'`; do find /dev/$user -amin +3 -exec pkill -9 -t $user \; ; done
for user in `w -h | grep pts | awk '{print $2}'`; do find /dev/$user -amin +3 -exec kill -9 `ps -ft $user | head -2 | tail -1 | awk '{print $2}'` \; ; done
