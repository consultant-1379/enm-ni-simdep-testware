#!/bin/sh
SIMDEP_LOCAL_DIR=$1
rolloutType=$2
LOCAL_IP_ADDRESS=`hostname -i`


if [ -f /etc/centos-release ]
then
  if [[ ${rolloutType} = "GCP" ]]
  then
      LOCAL_IP_ADDRESS1=`ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
      ifconfig -a | grep -i "inet " | awk '{print $2}' | grep -Ev "127.0.0.1|172.17" | grep -v "^$LOCAL_IP_ADDRESS$" | grep -v "^$LOCAL_IP_ADDRESS1$" > $SIMDEP_LOCAL_DIR/dat/avail_IpAddr_IPv4.txt

  else
     ifconfig -a | grep -i "inet " | awk '{print $2}' | grep -Ev "127.0.0.1|172.17" | grep -v "^$LOCAL_IP_ADDRESS$" > $SIMDEP_LOCAL_DIR/dat/avail_IpAddr_IPv4.txt
   fi 

   ifconfig -a | grep -i "inet6 " | awk '{print $2}' | sort -u | awk -F\/ '{print $1}' | grep -v -w "::1" > $SIMDEP_LOCAL_DIR/dat/avail_IpAddr_IPv6.txt
else
     ifconfig -a | grep -i "inet " | awk '{print $2}' | awk -F: '{print $2}' | sort -ut. -k1,1 -k2,2n -k3,3n -k4,4n | grep -Ev "127.0.0.1|172.17" | grep -v "^$LOCAL_IP_ADDRESS$" > $SIMDEP_LOCAL_DIR/dat/avail_IpAddr_IPv4.txt

    ifconfig -a | grep -i "inet6 " | grep "Scope:Global" | awk '{print $3}' | sort -u | awk -F\/ '{print $1}' > $SIMDEP_LOCAL_DIR/dat/avail_IpAddr_IPv6.txt
fi
