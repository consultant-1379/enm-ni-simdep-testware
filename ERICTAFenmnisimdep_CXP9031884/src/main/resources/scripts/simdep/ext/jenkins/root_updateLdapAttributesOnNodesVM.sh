#!/bin/sh

set -o pipefail

if [[ ! -f /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/updateLdapAttributesOnNodesVM.sh ]]
then
    echo "ERROR: Error UpdateLdapAttributesOnNodesVM.sh script node present"
    exit 1
fi

user=`whoami`
if [[ $user != "root" ]]
then
    echo "ERROR: Only Root user can excute this script"
    exit 1
fi

if [ $# -eq 0 ]
then
    echo "ERROR : No Parameters Passed"
    exit 1
fi

ConfigType=$1
Number_Of_BSC_Nodes=$2
Number_Of_LTE_Nodes=$3
TlsMode=$4
AuthenticationDelay=$5
clusterid=$6
Deployment=$7
ENM_URL=$8

touch Summary.log
chmod -R 777 Summary.log

su netsim -c "sh /var/simnet/enm-ni-simdep/scripts/simdep/ext/jenkins/updateLdapAttributesOnNodesVM.sh $ConfigType $Number_Of_BSC_Nodes $Number_Of_LTE_Nodes $TlsMode $AuthenticationDelay $clusterid $Deployment $ENM_URL > Summary.log"

if [[ $? -ne 0 ]]
then
    echo "ERROR: Script not executed successfully"
    exit 1
fi


if grep -e "does not exist" Summary.log; then
    echo "Something went wrong in the job"
    cat Summary.log
    exit 1
elif grep -e "pipeline command has failed" Summary.log; then
    echo "Something went wrong in the job"
    cat Summary.log
    exit 1
elif grep -q Error Summary.log; then
    echo " Logs have some Errors which can be ignored"
    cat Summary.log
else
    echo "It was a Successful Run"
    cat Summary.log
fi

