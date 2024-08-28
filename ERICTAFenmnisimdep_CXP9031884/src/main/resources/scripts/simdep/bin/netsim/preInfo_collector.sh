#!/bin/sh

#######################################################
#Created by  : zhainic
#Date        : May 27th,2020
#Arguments   : NSSDrop
#Usage       : sh preInfo_collector.sh 20.11
#use         : collects the port destination and Pm status before netsim update.
#######################################################i

Date=`date`
echo "$0 script started at $Date"


user=`whoami`
if [[ $user != "netsim" ]]
then
    echo "ERROR: Only netsim user can excute this script" | tee -a $LogFile
    exit 1
fi

if [[ $# -ne 1 ]]
then
    echo "ERROR: Invalid argument" | tee -a $LogFile
    echo "Usage: ./preInfo_collector.sh NSSDrop" | tee -a $LogFile
    exit 1
fi

NSSDrop=$1
netsim_check=`echo -e '\n' | /netsim/inst/netsim_shell`
if [[ $netsim_check == *"NETSim is not started"* ]] || [[ $netsim_check == *"restart_netsim"* ]]
then
    echo "Netsim was not started on the boxes......Unable to collect the data"
    exit 0
fi
sims=`echo -e '.show simulations\n' | /netsim/inst/netsim_shell -q | grep -vE 'default|zip'`
for sim in ${sims[@]}
do
#########################collecting  the port DD and DDIP of nodes ########################################
    nodeNames=`echo '.show simnes' | ~/inst/netsim_shell -q -sim ${sim} | grep -vE 'OK|NE' | cut -d ' ' -f1`
    for nodeName in ${nodeNames[@]}
    do
    PORT=`echo -e '.select '$nodeName'\ne simdiv:keysearch(port,netsimdb:lookup(simulation, {sim_nes, '\"${nodeName}\"'})).' | ~/inst/netsim_shell -q -sim ${sim} | grep -v 'OK'`
    DefaultDestination=`echo -e '.select '$nodeName'\ne simdiv:keysearch(external, netsimdb:lookup(simulation, {sim_nes, '\"${nodeName}\"'})).' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -v 'OK'`
    DDIP=`echo -e '.select '$nodeName'\ne protocollib:lookup_effective_dest_address_string(intcmdlib:current_simulation(), '\"${nodeName}\"').' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -v 'OK'`
    echo "$nodeName $PORT $DefaultDestination $DDIP" >> /var/simnet/SW_verification/${NSSDrop}/${sim}_PreData.log
    done

#################################collecting PMdata status of nodes ##########################################
echo -e '.select network\npmdata:status;\n' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -vE 'OK' > /var/simnet/SW_verification/${NSSDrop}/${sim}_PrePMdata.log
done

Date=`date`
echo "$0 script ended at $Date"
