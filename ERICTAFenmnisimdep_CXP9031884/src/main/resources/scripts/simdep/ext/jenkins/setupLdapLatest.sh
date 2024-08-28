#!/bin/sh
######################################################################################
#     File Name     : setupLdapLatest.sh
#     Version       : 1.00
#     Author        : Surabhi Ravi Teja
#######################################################################################
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
CLUSTER_ID=$1
ServerName=$2
deployment_type=$3
Number_Of_BSC_Nodes=$4
Number_Of_LTE_Nodes=$5
TlsMode=$6
AuthenticationDelay=$7
ConfigType=$8
LdapAttributesLog="/var/tmp/LdapAttributes.log"



##############################################
#Fetch ENM URL
##############################################
cd $WORKSPACE/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/
if [[ $deployment_type == "Cloud" ]]; then
	#Downlaoding Jq Files
    cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
    sed_id=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$CLUSTER_ID" | ./jq '.[].enm.sed_id' | sed 's/\"//g'`
    ClusterName=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$sed_id" | ./jq '.content.parameters.httpd_fqdn' | sed 's/\"//g' | awk -F. '{print $1}'`
	ENM_URL="https://$ClusterName.athtem.eei.ericsson.se/"
else
	ENM_URL=`python fetchEnmUrl.py $CLUSTER_ID`
	ENM_URL="https://$ENM_URL/"
fi

##########################################################
#Install Enm_Client_Scripting
##########################################################

#cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/get-pip.py .
sudo python get-pip.py
curl --insecure  --tlsv1 -c /tmp/cookie.txt -X POST "$ENM_URL/login?IDToken1=Administrator&IDToken2=TestPassw0rd"
ENMSCRIPTING_URL=`curl --insecure  --tlsv1 -b /tmp/cookie.txt --retry 5 -LsS -w %{url_effective} -o /dev/null "$ENM_URL/scripting/enmclientscripting"`
curl -L -O --insecure --tlsv1 -b /tmp/cookie.txt --retry 5 -fsS "$ENMSCRIPTING_URL"
sudo pip install enm_client_scripting*.whl

##########################################################
# Fetch LDAP Attribute on Master Server
##########################################################
cp runCliCommand.py /var/tmp/
sh fetchLdapAttributes.sh $ENM_URL


PPWD=$(pwd)
Cmd="$PPWD/updateLdapAttributesOnNodesVMLatest.sh"
GET_JQ_TAR="${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar"

IFS=' , ' read -r -a array <<< "$ServerName"

for serverName in "${array[@]}"
do
     echo "**************************************************************************************************************"
     echo "serverName is $serverName"
     echo "**************************************************************************************************************"

     /usr/bin/expect <<EOF
     set timeout -1
     spawn scp -rp -o StrictHostKeyChecking=no /var/tmp/LdapAttributes.log netsim@$serverName.athtem.eei.ericsson.se:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
     spawn scp -rp -o StrictHostKeyChecking=no $GET_JQ_TAR netsim@$serverName.athtem.eei.ericsson.se:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5

     spawn scp -rp -o StrictHostKeyChecking=no $Cmd netsim@$serverName.athtem.eei.ericsson.se:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
     spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName.athtem.eei.ericsson.se "chmod 777 /netsim/updateLdapAttributesOnNodesVMLatest.sh ; /netsim/updateLdapAttributesOnNodesVMLatest.sh $ConfigType $Number_Of_BSC_Nodes $Number_Of_LTE_Nodes $TlsMode $AuthenticationDelay"
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
	 spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName.athtem.eei.ericsson.se "rm -rf /netsim/updateLdapAttributesOnNodesVMLatest.sh"
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
EOF
done

OUTPUT=`cat /var/tmp/LdapAttributes.log | grep "Executed Successfully"`

if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
    echo "Successfully updated"
else
    echo "Not a proper file."
    exit 1
fi
