#!/bin/bash

# Created by  : CDB Team
# Modified by : Fatih ONUR
# Created on  : 2015.01.16

### VERSION HISTORY
# Version     : 1.0
# Purpose     : Checking sync status of the nodes 
# Description : Utility to check sync status of the nodes only at ONRM_CS and Seg_masterservice_CS
# Date        : 16 JAN 2015
# Who         : Fatih ONUR

# Absolute path this script is in. /home/user/bin
SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "SCRIPT_PATH=$SCRIPT_PATH"

NODENAMES=()
k=0
while read line
do
    NODENAMES[$k]=$line
    #echo "nodeName=${NODENAMES[$k]}"
    k=$(($k+1))
done < $SCRIPT_PATH/../dat/listNeName.txt
if [ $? -ne 0 ]
then
    echo "ERROR: FileName:listNeName.txt not found." 
    echo "Please locate listNeName.txt which contains nodeNames at the same place where this script."
    echo "Exiting(code:123)..."
    exit 123;
fi	
#exit

i=-1
j=0
NAME=()
NODEVERSION=""
var="$(/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS lt MeContext -f '$.mirrorMIBsynchStatus==5 OR $.mirrorMIBsynchStatus==3' -an userLabel | while read line
    do
	i=$(($(($i+1))%2))
        if [ "${i}" -eq "1" ]; then
	    j=$(($j+1))
            NAME[$j]=${line##*:} 
    	    NAME[$j]="`echo "${NAME[$j]}" | sed 's/"//g'`"

	    for element in ${NODENAMES[@]}
            do
                if [ ${element} == ${NAME[j]} ]; then
	            echo "${NAME[j]}"
                    break
                fi
            done

        fi
	
	done)"
unsynchvar="$(/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS lt MeContext -f '$.mirrorMIBsynchStatus==1 OR $.mirrorMIBsynchStatus==2 OR $.mirrorMIBsynchStatus==4' -an userLabel | while read line
    do
        i=$(($(($i+1))%2))
        if [ "${i}" -eq "1" ]; then
	    j=$(($j+1))
            NAME[$j]=${line##*:} 
            NAME[$j]="`echo "${NAME[$j]}" | sed 's/"//g'`"
	
            for element in ${NODENAMES[@]}
            do
                if [ ${element} == ${NAME[j]} ]; then
	            echo "${NAME[j]}"
		    break
		fi
            done
			
        fi
	
done)"


printf  "%-45s %-15s %-15s \n" "NodeName" "NodeVersion" "SynchStatus"
i=-1
NODENAME=""
NODEVERSION=""
/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt ManagedElement -an userLabel nodeVersion | while read line
do
    i=$(($(($i+1))%3))
    if [ "${i}" -eq "1" ]; then
        NODENAME=${line##*:}
        NODENAME[$j]="`echo "${NODENAME[$j]}" | sed 's/"//g'`"
    fi
    if [ "${i}" -eq "2" ]; then
        NODEVERSION=${line##*:}
	NODEVERSION[$j]="`echo "${NODEVERSION[$j]}" | sed 's/"//g'`"
	for element in ${var[@]}
	do
            if [ ${element} == ${NODENAME} ]; then
                printf "%-45s %-15s %-15s \n" "$NODENAME" "$NODEVERSION" "SYNC"
	    fi				
        done			
    fi
done


i=-1
NODENAME=""
NODEVERSION=""
/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS lt ManagedElement -an userLabel nodeVersion | while read line
do
    i=$(($(($i+1))%3))
    if [ "${i}" -eq "1" ]; then
        NODENAME=${line##*:}
	NODENAME[$j]="`echo "${NODENAME[$j]}" | sed 's/"//g'`"
    fi
    if [ "${i}" -eq "2" ]; then
	NODEVERSION=${line##*:}
	NODEVERSION[$j]="`echo "${NODEVERSION[$j]}" | sed 's/"//g'`"
	for element in ${unsynchvar[@]}
        do
            if [ ${element} == ${NODENAME} ]; then
                printf "%-45s %-15s %-15s \n" "$NODENAME" "$NODEVERSION" "UNSYNC"
	    fi		
	done
    fi
done	
