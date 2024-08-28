#!/bin/sh

###################################################################################
#Created by  : zhainic
#Date        : May 27th,2020
#Arguments   : NSSDrop
#Usage       : sh postPort_verification.sh 20.11
#use         : compares the port and destination post netsim update.
###################################################################################

Date=`date`
echo "$0 script started at $Date"


user=`whoami`
if [[ $user != "netsim" ]]
then
   echo "ERROR: Only netsim user can excute this script"
   exit 1
fi

if [[ $# -ne 1 ]]
then
    echo "ERROR: Invalid argument"
    echo "Usage: ./postPort_verification.sh NSSDrop"
    exit 1
fi

NSSDrop=$1

path="/var/simnet/SW_verification/${NSSDrop}"
hostName=`hostname`


sims=`echo -e '.show simulations\n' | /netsim/inst/netsim_shell -q | grep -vE 'OK|default|zip'`
for sim in ${sims[@]}
do
    echo "INFO: Verifing Port,Default Destination and DDIP for nodes of sim $sim\n"
    nodeNames=`echo '.show simnes' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -vE 'OK|NE' | cut -d ' ' -f1`
    for nodeName in ${nodeNames[@]}
    do
        PORT=`echo -e '.select '$nodeName'\ne simdiv:keysearch(port,netsimdb:lookup(simulation, {sim_nes, '\"${nodeName}\"'})).' | ~/inst/netsim_shell -q -sim ${sim} | grep -v 'OK'`

        DD=`echo -e '.select '$nodeName'\ne simdiv:keysearch(external, netsimdb:lookup(simulation, {sim_nes, '\"${nodeName}\"'})).' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -v 'OK'`

        DDIP=`echo -e '.select '$nodeName'\ne protocollib:lookup_effective_dest_address_string(intcmdlib:current_simulation(), '\"${nodeName}\"').' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -v 'OK'`

        echo "$nodeName $PORT $DD $DDIP" >> ${path}/${sim}_PostData.log
        info_line=`cat ${path}/${sim}_PreData.log | grep "${nodeName}"`
        PRE_PORT=`echo ${info_line} | cut -d ' ' -f2`
        PRE_DD=`echo ${info_line} | cut -d ' ' -f3`
        PRE_DDIP=`echo ${info_line} | cut -d ' ' -f4`

        #echo "NodeName is $nodeName"
        #echo "Post_PORT is $PORT Post_DD id $DD Post_DDIP is $DDIP"
        #echo "PRE_PORT is ${PRE_PORT} PRE_DD is ${PRE_DD} PRE_DDIP is ${PRE_DDIP}"

############################assigning the port########################
if [[ $PORT != $PRE_PORT ]]
then
    echo -e 'ERROR: There is a difference in port after the netsim update'
    echo -e "INFO: Post_PORT is $PORT PRE_PORT is ${PRE_PORT} for node $nodeName\nINFO: CORRECTING PORT\n"
    cat >> /tmp/post_update.mml << ABC
.open $sim
.select $nodeName
.stop -parallel
.modifyne checkselected .set port ${PRE_PORT} port
.set port ${PRE_PORT}
.set save
.start -parallel
ABC
    /netsim/inst/netsim_shell < /tmp/post_update.mml 
    rm -rf /tmp/post_update.mml
fi
##########################creating DD with IP########################
if [[ $DDIP != $PRE_DDIP ]]
then
    echo -e 'ERROR: There is a difference in DDIP after the netsim update'
    echo -e "INFO: Post_PORT is $DDIP PRE_PORT is ${PRE_DDIP} for node $nodeName\nINFO: CORRECTING DDIP\n"
    
    DATA=`echo -e '.open '$sim'\n.select '$nodeName'\ne netsimdb:lookup(configuration, {externals,'${PRE_DD}'}).\n' | /netsim/inst/netsim_shell `

    INFO=`echo $DATA | awk -F '}, ' '{print $1}' | awk -F 'address' '{print $2}' | tr -d '[{' | tr -d '}]'| tr -d '"'` 
    #IP=`echo $INFO | awk -F ',' '{print $2}'`
    IP=`echo ${PRE_DDIP} | awk -F ',' '{print $2}' | awk -F ':' '{print $1}' |tr -d '"'`
    UDP=`echo $INFO | awk -F ',' '{print $3}'`
    Notification=`echo $INFO | awk -F ',' '{print $4}'`
    prot=`echo $DATA | awk -F '}, ' '{print $2}' | awk -F 'protocol,' '{print $2}' | tr -d '"'`
    Pre_DD=`echo ${PRE_DD} | tr -d '"'`
    
    #echo -e "\n\n DATA is $DATA\nINFO is $INFO\n IP is $IP\nUDP is $UDP\nNotification is $Notification\n\n\n"

    output=`echo -e '.select configuration\n.config add external '${Pre_DD}' '${prot}'\n.config external servers '${Pre_DD}' '${hostName}'\n.config external address '${Pre_DD}' '${IP}' '${UDP}' '${Notification}'\n.config save\n' | /netsim/inst/netsim_shell`
    echo $output 
fi
###############################assigning the DD ############################
if [[ $DD != $PRE_DD ]]
then
    echo -e 'ERROR: There is a difference in DefaultDestination after the netsim update'
    echo -e "INFO: Post_PORT is $DD PRE_PORT is ${PRE_DD} for node $nodeName\nINFO: CORRECTING DD\n"
    
    cat >> /tmp/post_update.mml << ABC
.open $sim
.select $nodeName
.stop -parallel
.modifyne checkselected external ${PRE_DD} default destination
.set external ${PRE_DD}
.set save
.start -parallel
ABC
    /netsim/inst/netsim_shell < /tmp/post_update.mml 
    rm -rf /tmp/post_update.mml
fi

done
echo -e "INFO: Verification of port,DD and DDIP for nodes of $sim was done"
done

Date=`date`
echo "script ended at $Date"
