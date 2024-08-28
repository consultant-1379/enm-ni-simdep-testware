#!/bin/sh

deployment_type=$1
CLUSTER_ID=$2
ENM_URL=$3
drop=$4
nodesCleanUp=$5
if [[ $# -ne 5 ]]
then
echo "Error:Invalid number of parameters"
echo "Usage: ./$0 DeploymentType Deploymentname ENM_guiURL NSSDrop NodesCleanUP(YES/NO)"
echo "Ex: ./$0 physical 418 https://ieatenm5418-1.athtem.eei.ericsson.se/ 22.07 NO"
exit
fi
echo "CLUSTER_ID=$CLUSTER_ID"
echo "ENM_URL =$ENM_URL"
PWD=`pwd`
cp runCliCommand.py /var/tmp/
sh updateTrustProfileForVMs.sh $ENM_URL
OUTPUT=$(grep "sucessfully updated" /var/tmp/trustProfile.log)
if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
    echo "INFO: Trust Profile is successfully updated."
else
    echo "ERROR: Trust Profile is not successfully updated."
    exit 1
fi

if [[ $nodesCleanUp == "YES" || $nodesCleanUp == "yes" ]]
then
   sh nodesCleanUp.sh $CLUSTER_ID $drop $deployment_type > /var/tmp/nodesCleanUp.log
   status=$(cat /var/tmp/nodesCleanUp.log | grep -i "ERROR")
   if [[ ! -z $status ]]
   then
       echo "ERROR: nodesCleanup got failed"
       cat /var/tmp/nodesCleanUp.log
       exit 1
   else
       cat /var/tmp/nodesCleanUp.log
   fi
fi
sleep 30m
