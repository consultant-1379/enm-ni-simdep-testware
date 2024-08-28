#!/bin/sh
if [ "$(whoami)" == "netsim" ]; then
     echo "Executing the DST and NETSim GC cronupdate script as user netsim" > /tmp/CronUpdate.log
else
     echo "netsim user is only allowed to execute the DST and NETSim GC cronupdate script" > /tmp/CronUpdate.log
     exit 1
fi
days=0
network=`cat /netsim/simdepContents/NRMDetails | head -1 | cut -d '=' -f2`
HOSTNAME=`hostname`
if [[ $network == "NSS" || $HOSTNAME == "netsim" ]]
then
days=2
fi
echo "INFO: Logging files will be deleted for $days days";
sh /netsim/inst/netsimbase/inst/timezone_offset.sh > /netsim/inst/DSTChangeApply.log &

crontab -l > /tmp/NetsimUserCrontmp.txt
echo "00 * * * * sh /netsim/inst/netsimbase/inst/timezone_offset.sh > /netsim/inst/logfiles/DSTChangeApply.log" > /tmp/NetsimUserCrontmp.txt
cat /tmp/NetsimUserCrontmp.txt | grep -v "# " | grep -v "/tmp/ssh" | grep -v "/tmp/netconf" | awk '!seen[$0]++' > /tmp/NetsimUserCron.txt
crontab /tmp/NetsimUserCron.txt
rm /tmp/NetsimUserCrontmp.txt /tmp/NetsimUserCron.txt

crontab -l > /tmp/NetsimUserCrontmp.txt
cat /tmp/NetsimUserCrontmp.txt | grep -v "# " | grep -v "/tmp/ssh" | grep -v "/tmp/netconf" | sed '/Netsim RAM cleanup/,/Netsim RAM cleanup/d' | sed '/^$/d' | awk '!seen[$0]++' > /tmp/NetsimUserCron.txt
echo -e "\n##############################Netsim RAM cleanup######################################################"  >> /tmp/NetsimUserCron.txt
echo "0,15,30,45 * * * * echo -e '.e rpc:multicall(nodes(),erlang,spawn,[fun() -> [erlang:garbage_collect(P)||P<-erlang:processes()] end]).'|/netsim/inst/netsim_shell > /dev/null 2>&1"  >> /tmp/NetsimUserCron.txt
echo -e "##############################Netsim RAM cleanup######################################################"  >> /tmp/NetsimUserCron.txt
echo -e "7 * * * * sh /netsim/inst/netsimbase/inst/cbrstxexpiretime_filegen.sh > /netsim/inst/logfiles/cbrstxexpiretime_generator.log 2>&1" >> /tmp/NetsimUserCron.txt
echo -e "##############################cbrstx file generation##################################################" >> /tmp/NetsimUserCron.txt
echo -e "52 23 * * * sh /var/simnet/enm-ni-simdep/scripts/cbrsClean.sh > /dev/null 2>&1" >> /tmp/NetsimUserCron.txt
echo -e "##############################cbrst files deletion####################################################" >> /tmp/NetsimUserCron.txt
echo "0 0 * * * /var/simnet/enm-ni-simdep/scripts/Cleanlog.sh $days > /dev/null 2>&1"  >> /tmp/NetsimUserCron.txt
echo -e "##############################Cleanup logs############################################################"  >> /tmp/NetsimUserCron.txt
echo -e "\n3 */12 * * * sh /netsim/inst/netsimbase/inst/ConfResultM_Deletion.sh 24 > /netsim/inst/logfiles/ConfResultm_delete.log" >> /tmp/NetsimUserCron.txt
echo "############################# Delete GSM ConfResultMos ###############################################"  >> /tmp/NetsimUserCron.txt
echo -e "56 23 * * * sh /var/simnet/enm-ni-simdep/scripts/checkStartedNodesForddc.sh 2>&1" >> /tmp/NetsimUserCron.txt
echo -e "56 4,10,16,22 * * * sh /var/simnet/enm-ni-simdep/scripts/checkNumStartedNodesForddc.sh 2>&1" >> /tmp/NetsimUserCron.txt
echo "############################# clearNodeSpcTab script to crontab ###############################################"  >> /tmp/NetsimUserCron.txt
echo -e "35 * * * * sh /netsim/inst/netsimbase/inst/clearNodeSpcTab > /dev/null 2>&1" >> /tmp/NetsimUserCron.txt
echo -e "30 0 * * 6 rm -f /netsim/clearSpcLogs/clearSpcTabLogs.log > /dev/null 2>&1" >> /tmp/NetsimUserCron.txt
crontab /tmp/NetsimUserCron.txt
rm /tmp/NetsimUserCrontmp.txt  /tmp/NetsimUserCron.txt
