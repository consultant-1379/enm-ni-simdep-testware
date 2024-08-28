#!/bin/sh

NRM=`cat /netsim/simdepContents/NRMDetails | grep -v "RolloutNetwork" | awk -F '=' '{print $2}'`
Network=`cat /netsim/simdepContents/NRMDetails | grep "RolloutNetwork" | awk -F '=' '{print $2}'`
if [[ -z $NRM ]]
then
echo "NRM Details was not present on server"
elif [[ $NRM != "NSS" ]]
then
su netsim -c "echo -e '.set env RV\n' | /netsim/inst/netsim_shell"
else
echo "Not RV network"
fi
################ciphers skip for specific networks################

if [[ $Network == "rvModuleLRAN_60KCells_vLarge_NRM1.2" ]] || [[ $Network == "rvModuleWRAN_10KCells_NRM5" ]] || [[ $Network == "rvModuleGRAN_30KCells_NRM5" ]]
then
su netsim -c "echo -e '.set checkciphers yes\n' | /netsim/inst/netsim_shell"
fi