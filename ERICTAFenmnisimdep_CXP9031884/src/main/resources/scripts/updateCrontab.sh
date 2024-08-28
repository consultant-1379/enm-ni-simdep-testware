#!/bin/sh

if [ $# -ne 1 ]
then
echo "ERROR: invalid arguments"
fi
crontab -l | grep -vE "/proc/sys/vm/drop_caches" > /tmp/rootCrontmp.txt
echo -e "40 * * * * sleep 15;sync; echo 3 > /proc/sys/vm/drop_caches " >> /tmp/rootCrontmp.txt
crontab -l | grep -E "vmusagecheck.sh" > /tmp/check.txt
if [[ ! -s /tmp/check.txt ]]
then
echo -e  "56 7 * * * sh /var/simnet/enm-ni-simdep/scripts/vmusagecheck.sh > /dev/null 2>&1" >> /tmp/rootCrontmp.txt
else
 cat /tmp/check.txt | grep -E "42 0" > /tmp/check1.txt
  if [[  -s /tmp/check1.txt ]]
  then
	  sed -i 's/42 0/56 7/' /tmp/rootCrontmp.txt
  fi
fi
crontab /tmp/rootCrontmp.txt
rm -rf /tmp/check.txt
rm -rf /tmp/rootCrontmp.txt

nssDrop=$1

if [[ ${nssDrop//./} > "1910" ]]
then
su -c 'sh /var/simnet/enm-ni-simdep/scripts/changeCrontab.sh' - netsim
else
echo "No Crontab Changes are required"
fi
