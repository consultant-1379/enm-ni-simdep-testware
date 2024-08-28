#!/bin/sh
PWD=`pwd`
LOCAL_IP_ADDRESS=`hostname -i`
rolloutType=$1

#echo ".show allsimnes" | /netsim/inst/netsim_shell | awk -F" " '{print $2}' | sed '/^$/d' | grep -v "[a-z][A-Z]*"  | awk -F":" '{print $1}'| grep -v ":" | sed '/^NE/d' > ../dat/dumpUsedIps_Intermediate.txt

#cat ../dat/dumpUsedIps_Intermediate.txt | awk -F"," '{print $1}'  > ../dat/dumpUsedIps.txt

#cat ../dat/dumpUsedIps_Intermediate.txt | awk -F"," '{print $2}' | sed '/^$/d' >> ../dat/dumpUsedIps.txt


#cat ../dat/dumpUsedIps_Intermediate.txt | awk -F"," '{print $3}' | sed '/^$/d' >> ../dat/dumpUsedIps.txt

#rm ../dat/dumpUsedIps_Intermediate.txt
#echo "$LIST_OF_IPS" | grep '^[0-9]\{3\}\.' |awk -F":" '{print $1}' | awk -F"," '{for (i=1; i<=NF; i++) print $i}' | sort -ut. -k1,1 -k2,2n -k3,3n -k4,4n > ../dat/used_IpAddr_IPv4.txt

if [ -f /etc/centos-release ]
then
   if [[ ${rolloutType} = "GCP" ]]
   then
       LOCAL_IP_ADDRESS1=` ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`

       lsof -n -i4 | grep -v ntp | awk '{print $9}' | awk -F ":" '{print $1}' | grep -vE '(vmx|ieatnetsim|netsim|NAME|localhost|127.0.0.1|\*)' | awk 'NF' | sort | uniq | grep -v "^$LOCAL_IP_ADDRESS$" | grep -v "^$LOCAL_IP_ADDRESS1$" > ../dat/UsedIPv4s.log

       lsof -n -i6 | grep -v ntp | awk '{print $9}' | awk -F "]" '{print $1}' | awk -F "[" '{print $2}' | grep -vE '(vmx|netsim|ieatnetsim|NAME|localhost|\*)' | awk 'NF' | sort | uniq | grep -v "^$LOCAL_IP_ADDRESS$" | grep -v "^$LOCAL_IP_ADDRESS1$" > ../dat/UsedIPv6s.log

   else
       lsof -n -i4 | grep -v ntp | awk '{print $9}' | awk -F ":" '{print $1}' | grep -vE '(vmx|ieatnetsim|netsim|NAME|localhost|127.0.0.1|\*)' | awk 'NF' | sort | uniq | grep -v "^$LOCAL_IP_ADDRESS$" > ../dat/UsedIPv4s.log

       lsof -n -i6 | grep -v ntp | awk '{print $9}' | awk -F "]" '{print $1}' | awk -F "[" '{print $2}' | grep -vE '(vmx|netsim|ieatnetsim|NAME|localhost|\*)' | awk 'NF' | sort | uniq | grep -v "^$LOCAL_IP_ADDRESS$" > ../dat/UsedIPv6s.log
   fi
else
   lsof -i4 | grep -v ntp | awk '{print $9}' | awk -F ":" '{print $1}' | grep -vE '(ieatnetsim|NAME|localhost|\*)' | awk 'NF' | sort | uniq > ../dat/UsedIPv4s.log

   lsof -i6 | grep -v ntp |awk '{print $9}' | awk -F "]" '{print $1}' | awk -F "[" '{print $2}' | grep -vE '(ieatnetsim|NAME|localhost|\*)' | awk 'NF' | sort | uniq  > ../dat/UsedIPv6s.log
fi
LIST_OF_IPS=`echo ".show allsimnes" | /netsim/inst/netsim_shell |  awk -F" " '{print $2}'` 

echo "$LIST_OF_IPS" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |awk -F":" '{print $1}' | awk -F"," '{for (i=1; i<=NF; i++) print $i}' | sort -ut. -k1,1 -k2,2n -k3,3n -k4,4n > ../dat/dumpUsedIps_Intermediate.txt

cat ../dat/dumpUsedIps_Intermediate.txt ../dat/UsedIPv4s.log | grep -v ":" | sort | uniq > ../dat/used_IpAddr_IPv4.txt

echo "$LIST_OF_IPS" | grep ":" > ../dat/dumpUsedIps_Intermediate.txt

cat ../dat/dumpUsedIps_Intermediate.txt ../dat/UsedIPv6s.log | grep  ":" | sort | uniq > ../dat/used_IpAddr_IPv6.txt

