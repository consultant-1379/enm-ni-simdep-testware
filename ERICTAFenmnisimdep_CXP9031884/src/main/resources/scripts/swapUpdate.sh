#!/bin/sh

if [ -f /etc/centos-release ]
then
    echo "INFO: No need of swapMemory correction for CentOS"
else
    CurrentSwap=`free -g | grep -w "Swap:" | awk '{print $2}'`
    Network=`ls /netsim/simdepContents/ | grep -E "Simnet_1_8K|Simnet_nssModule_RFA250" | wc -l`
    if [ $CurrentSwap -lt 16 ]
    then
        echo "INFO: current swapMemory is $CurrentSwap gb";
        if [ $Network -eq 1 ]
        then
            echo "INFO: we won't update swapmemory for 1.8k and 2k networks in simdep rollout"
        else
            echo "INFO: 16GB of Swap was not present on server..Updating now"
            sh /var/simnet/enm-ni-simdep/scripts/updateSwapMemory.sh
        fi
    else
        echo "INFO: 16GB of swapmemory was present on server"
    fi
fi
