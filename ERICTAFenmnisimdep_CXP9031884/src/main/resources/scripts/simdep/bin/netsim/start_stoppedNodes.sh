#!/bin/sh
##############################################################################
#     File Name    : start_stoppedNodes.sh
#
#     Author       : -
#
#     Description  : Kills the stopped nodes servernode and restarts all stopped
#                    nodes
#
#     Date Created : 30 June 2020
#
#     Syntax       : ./start_stoppedNodes.sh
#     
#     Parameters   : No
#
###############################################################################
#Checking the user
########################################################################

user=`whoami`
if [[ $user != "netsim" ]]
then
        echo "ERROR: Only netsim user can execute this script"
        exit 1
fi

echo ".show allsimnes" | /netsim/inst/netsim_shell | grep not > stoppedNodes.tmp

while read line; do
      nodeName=`echo $line | awk '{print $1}'`
      nodeIp=`echo $line | awk '{print $2}'`
      Count=`echo "$nodeIp" | awk -F"." '{print NF-1}'`
      if [[ $Count == 0 ]]
      then
          lsof -i@[$nodeIp] > ipv6Pid.tmp
          Pid=`sed -n '2p' ipv6Pid.tmp |  awk '{print $2}'`
          if [[ $Pid != "" ]]
          then
              echo "Node $nodeName NodeIp $nodeIp pid $Pid"
              kill $Pid
          fi
      else
          lsof -i@"$nodeIp" > ipv4Pid.tmp
          Pid=`sed -n '2p' ipv4Pid.tmp |  awk '{print $2}'`
          if [[ $Pid != "" ]]
          then
              echo "Node $nodeName NodeIp $nodeIp pid $Pid"
              kill $Pid
          fi
      fi
  done < stoppedNodes.tmp
  
# rm -f stoppedNodes.tmp ipv4Pid.tmp ipv6Pid.tmp

sleep 40

Sims=`echo ".show simulations" | /netsim/inst/netsim_shell -q | grep -v zip | grep -v default`

for Sim in $Sims; do
    
    echo -e ".select network \n neuptime;" | /netsim/inst/netsim_shell -q -sim ${Sim} | grep -e "Not started" -e "NOT ACCEPTED" | awk -F ":" '{print $1}' > /netsim/${Sim}_stoppedNodes.tmp

    while read node; do
        if [[ $node == *"Not started"* ]]; then
            echo -e ".open ${Sim} \n .select network \n .stop \n .start -parallel 5" | /netsim/inst/netsim_shell
        else
            echo -e ".select ${node} \n .restart" | /netsim/inst/netsim_shell -sim ${Sim}
        fi
    done < /netsim/${Sim}_stoppedNodes.tmp
done


rm -f /netsim/*_stoppedNodes.tmp

echo "Stopped node count: `echo ".show allsimnes" | /netsim/inst/netsim_shell | grep -c not`"
