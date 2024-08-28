#!/bin/sh

crontab -l > /tmp/updateCronnetsim.txt
days=`cat /tmp/updateCronnetsim.txt | grep Cleanlog.sh | awk -F '.sh ' '{print $2}' | awk -F '> ' '{print $1}'`
echo "days are $days"

if [[ -z $days ]]
then
num=`cat /tmp/updateCronnetsim.txt | grep -n Cleanlog.sh | awk -F ':' '{print $1}'`
sed -i '/Cleanlog.sh/d' /tmp/updateCronnetsim.txt
days=0
network=`cat /netsim/simdepContents/NRMDetails | head -1 | cut -d '=' -f2`
HOSTNAME=`hostname`
if [[ $network == "NSS" || $HOSTNAME == "netsim" ]]
then
days=2
fi
echo "INFO: Logging files will be deleted for $days days"
sed -i "${num} i 0 0 * * * /var/simnet/enm-ni-simdep/scripts/Cleanlog.sh ${days} > /dev/null 2>&1" /tmp/updateCronnetsim.txt
crontab /tmp/updateCronnetsim.txt
rm /tmp/updateCronnetsim.txt
else
echo "Days required for cleanlog script are already updated"
fi
########################Updating cbrst files in crontab #########################################
echo "Updating cbrst files"
crontab -l | grep -v '^# ' | grep -vE 'cbrstxexpiretime_filegen.sh|cbrsClean.sh|cbrst|del_EUtranFreqAndRel_cbrs.sh|checkNumStartedNodesForddc.sh' > /tmp/NetsimCrontemp.txt
echo -e "7 * * * * sh /netsim/inst/netsimbase/inst/cbrstxexpiretime_filegen.sh > /netsim/inst/logfiles/cbrstxexpiretime_generator.log 2>&1" >> /tmp/NetsimCrontemp.txt
echo -e "##############################cbrstx file generation##################################################" >> /tmp/NetsimCrontemp.txt
echo -e "52 23 * * * sh /var/simnet/enm-ni-simdep/scripts/cbrsClean.sh > /dev/null 2>&1" >> /tmp/NetsimCrontemp.txt
echo -e "##############################cbrst files deletion####################################################" >> /tmp/NetsimCrontemp.txt

check_log=`cat /tmp/NetsimCrontemp.txt | grep -E 'DSTChangeApply.log|ConfResultm_delete.log'`

if [[ $check_log == *"logfiles"* ]]
then
  echo "INFO: DSTChangeApply logs are stored in /netsim/inst/logfiles/ only"
else
  echo "INFO: DSTChangeApply logs are not stored in /netsim/inst/logfiles/ modifying the cron"
  echo "00 * * * * sh /netsim/inst/netsimbase/inst/timezone_offset.sh > /netsim/inst/logfiles/DSTChangeApply.log" >> /tmp/NetsimCrontemp.txt
  echo -e "\n3 */12 * * * sh /netsim/inst/netsimbase/inst/ConfResultM_Deletion.sh 24 > /netsim/inst/logfiles/ConfResultm_delete.log" >> /tmp/NetsimCrontemp.txt
fi
crontab -l | grep -E "checkStartedNodesForddc.sh" > /tmp/checkStartedNodesForddc.txt
if [[ ! -s /tmp/checkStartedNodesForddc.txt ]]
then 
	echo -e "56 23 * * * sh /var/simnet/enm-ni-simdep/scripts/checkStartedNodesForddc.sh 2>&1" >> /tmp/NetsimCrontemp.txt
fi
rm /tmp/checkStartedNodesForddc.txt
echo -e "56 22,16,10,4 * * * sh /var/simnet/enm-ni-simdep/scripts/checkNumStartedNodesForddc.sh 2>&1" >> /tmp/NetsimCrontemp.txt
check_log1=`cat /tmp/NetsimCrontemp.txt | grep '/netsim/inst/netsimbase/inst/clearNodeSpcTab'`
check_log2=`cat /tmp/NetsimCrontemp.txt | grep 'clearSpcTabLogs.log'`
check_log3=`cat /tmp/NetsimCrontemp.txt | grep '/netsim/inst/clearNodeSpcTab'`

if [[ -z $check_log1 ]] && [[ -z $check_log3 ]]
then 
    echo -e "35 * * * * sh /netsim/inst/netsimbase/inst/clearNodeSpcTab > /dev/null 2>&1" >> /tmp/NetsimCrontemp.txt
elif [[ -z $check_log1 ]]
then 
    sed -i '/\/netsim\/inst\/clearNodeSpcTab/d' /tmp/NetsimCrontemp.txt
    echo -e "35 * * * * sh /netsim/inst/netsimbase/inst/clearNodeSpcTab > /dev/null 2>&1" >> /tmp/NetsimCrontemp.txt
else
    sed -i '/\/netsim\/inst\/clearNodeSpcTab/d' /tmp/NetsimCrontemp.txt
fi

if [[ -z $check_log2 ]]
then 
    echo -e "30 0 * * 6 rm -f /netsim/clearSpcLogs/clearSpcTabLogs.log > /dev/null 2>&1" >> /tmp/NetsimCrontemp.txt
fi
crontab /tmp/NetsimCrontemp.txt
rm -rf /tmp/NetsimCrontemp.txt
rm -rf /tmp/del_EUtranFreqAndRel_cbrs.txt
