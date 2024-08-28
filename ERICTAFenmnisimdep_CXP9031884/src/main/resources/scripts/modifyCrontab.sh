#!/bin/bash
crontab -l > /tmp/rootCrontmp.txt
if [ ! -f /etc/centos-release ]
then
echo "40 * * * * sleep 15;sync; echo 3 > /proc/sys/vm/drop_caches" >> /tmp/rootCrontmp.txt
fi
echo -e "56 7 * * * sh /var/simnet/enm-ni-simdep/scripts/vmusagecheck.sh > /dev/null 2>&1" >> /tmp/rootCrontmp.txt
cat /tmp/rootCrontmp.txt | grep -v "# " | awk '!seen[$0]++' > /tmp/rootCrontab.txt
crontab /tmp/rootCrontab.txt
rm /tmp/rootCrontmp.txt /tmp/rootCrontab.txt
su -c 'sh /var/simnet/enm-ni-simdep/scripts/netsimCronUpdate.sh' - netsim

echo "INFO: Running /var/simnet/enm-ni-simdep/scripts/swapUpdate.sh"

sh /var/simnet/enm-ni-simdep/scripts/swapUpdate.sh
