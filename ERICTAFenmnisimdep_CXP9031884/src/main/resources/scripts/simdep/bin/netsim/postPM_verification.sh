#!/bin/sh

###################################################################################
#Created by  : zhainic
#Date        : May 27th,2020
#Arguments   : NSSDrop
#Usage       : sh postPM_verification.sh 20.11
#use         : compares the Pm status post netsim update.
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
    echo "Usage: ./postPM_verification.sh NSSDrop"
    exit 1
fi

NSSDrop=$1

path="/var/simnet/SW_verification/${NSSDrop}"

sims=`echo -e '.show simulations\n' | /netsim/inst/netsim_shell -q | grep -vE 'default|zip'`
for sim in ${sims[@]}
do
    pre_out=`cat ${path}/${sim}_PrePMdata.log`
    if [[ $pre_out == *"Command not found: pmdata"* ]]
    then
        echo "INFO: Pmdata was not applicable on $sim"
     elif [[ $pre_out == "disabled" ]]
     then
        echo "INFO: Pmdata was disabled on $sim before netsim upgrade"
     elif [[ $pre_out == "enabled" ]]
     then
        echo "INFO: Pmdata was enabled on $sim before Netsim update"
        echo "INFO: Checking the Pm data after Netsim update"
        pm_data=`echo -e '.open '$sim'\n.select network\npmdata:status;\n' | /netsim/inst/netsim_shell | grep -vE 'OK|>>'`
#        echo "'''''''''''''''''''*$pm_data*''''''''*$pre_out*'''''''''''"

        if [[ "${pm_data}" == "${pre_out}" ]]
        then
           echo "INFO: Pm data was enabled on $sim even after netsim update"
        else
            echo "INFO: Pm data was disbaled on $sim after netsim update now enabling/CORRECTING pmdata to fix issue"
           output=`echo -e '.open '$sim'\n.select network\npmdata:enable;\n' | /netsim/inst/netsim_shell`
           echo "$output"
         fi

     else
         echo -e "INFO: Pm data was enabled on some of nodes of $sim\nINFO: Checking pmstatus of those nodes after netsim upgrade"
         if [ -f /netsim/${sim}_pm.mml ]
          then
              rm -rf /netsim/${sim}_pm.mml
         fi
         echo -e '.select network\npmdata:status;\n' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -vE 'OK|>>' > ${path}/${sim}_PostPMdata.log
         nodeNames=`echo -e '.show simnes\n' | /netsim/inst/netsim_shell -q -sim ${sim} | grep -vE 'OK|NE' | cut -d ' ' -f1`
         for nodeName in ${nodeNames[@]}
         do
             pre_PM=`cat ${path}/${sim}_PrePMdata.log | grep ${nodeName}`
             post_PM=`cat ${path}/${sim}_PostPMdata.log | grep ${nodeName}`
             #echo "*********************************${nodeName} pre is ${pre_PM} post is ${post_PM}***************"
             if [[ ${pre_PM} == *"enabled"* ]] && [[ ${post_PM} == *"disabled"* ]]
             then
cat >> /netsim/${sim}_pm.mml << ABC
.open $sim
.select $nodeName
pmdata:enable;
ABC
             fi
          done
          if [ -f /netsim/${sim}_pm.mml ]
          then
              echo -e "INFO: Pmdata was disbaled on some of nodes of $sim after netsim update\nINFO: Correcting/enabling the data on those nodes\n"
              /netsim/inst/netsim_shell < ${sim}_pm.mml
              rm -rf /netsim/${sim}_pm.mml
           else
              echo -e "INFO: Pmdata was enabled even after netsim upgrade on $sim"
           fi
     fi
done
