#!/bin/sh
######################################################################################
#     File Name     : setupUpdateTrustProfile.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : Setup Script to update trust profiles at ENM Side
#     Date Created  : 09 June 2017
#######################################################################################
#
trap onError INT TERM EXIT
set -o nounset  # will exit the script if an uninitialised variable is used.
set -o errexit  # will exit the script if any statement returns a non-true return value.
set -o pipefail # will take the error status of any item in a pipeline.

function onError {
    if [[ $? -ne 0 ]]
    then
        echo "[ERROR] A pipeline command has failed at line:"
        n=0
        # The caller builtin command is used to print execution frames of subroutine calls.
        # The topmost execution frame information is printed ("who called me") with line number and filename.
        while caller $((n++)); do :; done;
    fi
}
##############################################
#Variable declarations
##############################################
if [ $# == 4 ]
then
CLUSTER_ID=$1
deploymentType=$2
clusterName=$3
ENM_URL=$4
else
CLUSTER_ID=$1
deploymentType=$2
clusterName=$3
fi

    path="${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/"
##############################################
#Fetch ENM URL
##############################################
cd $path
if [ $# == 3 ]
then
if [[ $CLUSTER_ID == *"ieat"* ]]; then
    ENM_URL="https://$CLUSTER_ID/"
    if [[ $? -ne 0 ]]
    then
       echo "ERROR INFO: Fetching ENM_URL failed"
   fi
else
    ENM_URL=`./fetchEnmUrl.py $CLUSTER_ID`
    if [[ $? -ne 0 ]]
    then
       echo "ERROR INFO: Fetching ENM_URL failed"
   fi  
    ENM_URL="https://$ENM_URL/"
fi
fi
echo -e "CLUSTER_ID=$CLUSTER_ID ENM_URL=$ENM_URL"
##########################################################
#Install Enm_Client_Scripting
##########################################################
rm -rf enm_client_scripting*.whl
#cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/get-pip.py .
sudo python get-pip.py
curl --insecure --tlsv1.2 -c /tmp/cookie.txt -X POST "$ENM_URL/login?IDToken1=Administrator&IDToken2=TestPassw0rd"
ENMSCRIPTING_URL=`curl --insecure --tlsv1.2 -b /tmp/cookie.txt --retry 5 -LsS -w %{url_effective} -o /dev/null "$ENM_URL/scripting/enmclientscripting"`
if [[ $? -ne 0 ]]
    then
       echo "ERROR INFO: Fetching ENMSCRIPTING_URL failed"
   fi  
curl -L -O --insecure --tlsv1.2 -b /tmp/cookie.txt --retry 5 -fsS "$ENMSCRIPTING_URL"
sudo pip install enm_client_scripting*.whl
##########################################################
# Update Trust Profile on Master Server
##########################################################
cp runCliCommand.py /var/tmp/
cp modifyXml.py /var/tmp/
sh updateTrustProfileForVMs.sh $ENM_URL

OUTPUT=$(grep "sucessfully updated" /var/tmp/trustProfile.log)

if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
    echo "INFO: Trust Profile is successfully updated."
else
    echo "ERROR: Trust Profile is not successfully updated."
    exit 1
fi

sh updateCRL.sh ${deploymentType} ${clusterName} ${ENM_URL}
cat /var/tmp/crlUpdate.log
OUTPUT=$(grep "updated successfully" /var/tmp/crlUpdate.log)
if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
    echo "INFO: CRL is successfully updated."
else
    echo "ERROR: CRL is not successfully updated."
    exit 1
fi
rm -rf /tmp/cookie.txt
