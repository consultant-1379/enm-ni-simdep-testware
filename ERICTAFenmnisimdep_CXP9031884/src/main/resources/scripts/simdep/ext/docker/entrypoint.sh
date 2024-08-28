#!/bin/bash
#####################################################################
# File Name    : entrypoint.sh
# Version      : 1.00
# Author       : Fatih ONUR
# Description  : Configures NETSim and start nodes
# Date Created : 2017.01.26
#####################################################################

set -o errexit # exit when a command fails.
set -o nounset # exit when this script tries to use undeclared variables
set -o pipefail # to catch pipe errors

# Simdep: Setup for NETSim and internal release
#echo "$HOSTNAME" > /etc/hostname
echo "netsim" > /etc/hostname
sed -i "s/#ListenAddress 0.0.0.0/ListenAddress netsim/g" /etc/ssh/sshd_config \
  &&  head -n -1 /etc/hosts > /etc/host_temp; echo "`hostname -i`     netsim" >> /etc/host_temp; cat /etc/host_temp > /etc/hosts; rm -rf /etc/host_temp \
  && cat /etc/hostname \
  && cat /etc/hosts \
  && cat /etc/ssh/sshd_config | grep -i "Listen" \
  &&  /usr/sbin/sshd  \
  && echo "**************configuring ips******************" \
  && for i in {1..255} ; do ifconfig eth0:$i 192.168.100.$i netmask 255.255.255.0; done \
  && for i in {1..255} ; do ifconfig eth0:`expr 255+$i` 192.168.101.$i netmask 255.255.255.0; done \
  && ifconfig | grep "192.168.100." |wc -l \
  && ifconfig | grep "192.168.101." |wc -l 
  echo "entering in try block***********" \
  && while read -r ip; do ifconfig eth0 inet6 add "${ip}" ; done < /netsim/docker/avail_IpAddr_IPv6.txt \
  && xinetd -stayalive \
  && nohup /usr/sbin/cron \
  && mount -a  \
  && export SYSTEMD_NO_WRAP=true \
  && time su netsim -c /netsim/inst/start_netsim \
  && su netsim -c "/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/createPort.pl 192.168.0.12 yes" \
  && echo "*****************create port complete*********************" \
       
cd /var/simnet/enm-ni-simdep/scripts/
./generateNetworkMap.pl

#echo "*********************genstats script run**************************"
cd /netsim/
#sh /netsim/genstats_rollout_docker.sh ${SRV}:${PSV}

#chmod 644 /etc/hosts

# ENV variable which can be passed via external tools. e.g. docker-compose
# Usage example in docker-compose.yml file:
#   environment:
#   - ENTRYPOINT_ARGS=--regExp LTE02|LTE01
ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS:-""}"

if [[ "${ENTRYPOINT_ARGS}" == "" ]]; then
  echo "***********in if**************";
  echo "INFO: Executing: exec sudo -u netsim perl /netsim/docker/startSims.pl $@"
  exec sudo -u netsim perl "/netsim/docker/startSims.pl" "$@"
else
  echo "****************in else****************";
  echo "ENTRYPOINT_ARGS is $ENTRYPOINT_ARGS***";
  echo "INFO: Executing: exec sudo -u netsim perl /netsim/docker/startSims.pl ${ENTRYPOINT_ARGS}"
  IFS=' ' read -r -a ARGS <<< "$ENTRYPOINT_ARGS"
  echo "ARGS=${ARGS[@]}"
  exec sudo -u netsim perl "/netsim/docker/startSims.pl" "${ARGS[@]}"
fi
#echo "sleep start"
#sleep 5m



