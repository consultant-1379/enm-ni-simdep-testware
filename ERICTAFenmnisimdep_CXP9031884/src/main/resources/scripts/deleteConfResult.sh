#!/bin/sh
# Created by  : Harish Dunga
# Created on  : 2018.02.13
# File name   : deleteConfResult.sh 

simsList=`ls /netsim/netsimdir | grep GSM | grep BSC | grep -v zip`
if [ -e /netsim/inst/remove_Conf_resultMos.log ]
then
   ### removing old Conf_resultMo log ###
   rm /netsim/inst/remove_Conf_resultMos.log
fi
### Checking for GSM simulations ####
if [[ $simsList == "" ]]
then
   exit 1
fi
integers='^[0-9]+$' ## integral values ###
workingPath=`pwd`
simulations=(${simsList// / })
for simName in ${simulations[@]}
do
   echo netsim | sudo -S -H -u netsim bash -c 'echo -e ".open '$simName' \n.select network\n.start" | /netsim/inst/netsim_shell' 2>&1 >/dev/null
   if [ $? != 0 ]; then
      echo "ERROR: The nodes are not properly started in $simName"
      continue;
   else
      nodesList=`echo netsim | sudo -S -H -u netsim bash -c 'echo -e ".open '$simName' \n.show simnes" | /netsim/inst/netsim_shell' | grep "LTE BSC" | cut -d" " -f1`
      nodes=(${nodesList// / })
      for node in ${nodes[@]}
      do
         if [ -e $workingPath/moIds.txt ]
         then
            rm $workingPath/moIds.txt
         fi
         echo netsim | sudo -S -H -u netsim bash -c 'echo -e ".open '$simName'\n.select '$node'\ne [W11|W22] = csmo:get_mo_ids_by_type(null,\"BscM:ConfResult\").\ne W11.\ne W22." | /netsim/inst/netsim_shell' > moIds.txt
         head=`awk 'NR==8' moIds.txt`
         if ! [[ $head =~ $integers ]] ; then
            echo "No Conf result mos are present on $node"
            continue;
         else
            tailList=`awk 'NR==10' moIds.txt`
            echo netsim | sudo -S -H -u netsim bash -c 'echo -e ".open '$simName'\n.select '$node'\ne: csmodb:delete_mo_by_id(null, '$head')." | /netsim/inst/netsim_shell'
            tailList=$(echo $tailList | sed 's/[][]//g')
            moIds=(${tailList//,/ })
            for moId in ${moIds[@]}
            do
               echo netsim | sudo -S -H -u netsim bash -c 'echo -e ".open '$simName'\n.select '$node'\ne: csmodb:delete_mo_by_id(null, '$moId')." | /netsim/inst/netsim_shell'
            done
         fi
         rm -rf $workingPath/moIds.txt
      done
   fi
done
