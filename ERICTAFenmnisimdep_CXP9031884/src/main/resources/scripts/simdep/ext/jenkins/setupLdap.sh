#!/bin/sh
######################################################################################
#     File Name     : setupLdap.sh
#     Version       : 1.00
#     Author        : Mitali Sinha
#######################################################################################
######################################################################################
#     File Name     : setupLdap.sh
#     Version       : 1.01
#     JIRA          : NSS-37430
#     Date          : 20-10-2021
#     Author        : Mitali Sinha
#######################################################################################
trap onError INT TERM EXIT
#set -o nounset  # will exit the script if an uninitialised variable is used.
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
ENM_URL=$9
LdapAttributesLog="/var/tmp/LdapAttributes.log"
GET_JQ_TAR="${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar"


##############################################
#Fetch ENM URL
##############################################
cd $WORKSPACE/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/
if [[ -z $ENM_URL ]]; then
 if [[ $deployment_type == "Openstack" ]]; then
        #Downlaoding Jq Files
    cp $WORKSPACE/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
    sed_id=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$CLUSTER_ID" | ./jq '.[].enm.sed_id' | sed 's/\"//g'`
    ClusterName=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$sed_id" | ./jq '.content.parameters.httpd_fqdn' | sed 's/\"//g' | awk -F. '{print $1}'`
        ENM_URL="https://$ClusterName.athtem.eei.ericsson.se/"
 else
        ENM_URL=`python fetchEnmUrl.py $CLUSTER_ID`
        ENM_URL="https://$ENM_URL/"
 fi
fi
echo "## ENM_URL=$ENM_URL ## "

echo "## CLUSTER_ID=$CLUSTER_ID ##"
##########################################################
#Install Enm_Client_Scripting
##########################################################
#cp $WORKSPACE/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/get-pip.py .
sudo python get-pip.py
curl --insecure  --tlsv1 -c /tmp/cookie.txt -X POST "$ENM_URL/login?IDToken1=Administrator&IDToken2=TestPassw0rd"
ENMSCRIPTING_URL=`curl --insecure  --tlsv1 -b /tmp/cookie.txt --retry 5 -LsS -w %{url_effective} -o /dev/null "$ENM_URL/scripting/enmclientscripting"`
echo "## ENMSCRIPTING_URL=$ENMSCRIPTING_URL ##"
curl -L -O --insecure --tlsv1 -b /tmp/cookie.txt --retry 5 -fsS "$ENMSCRIPTING_URL"
sudo pip install enm_client_scripting*.whl

##########################################################
# Fetch LDAP Attribute on Master Server
##########################################################
cp runCliCommand.py /var/tmp/
if [[ "$ConfigType" == "ENABLE" ]] ; then 
sh fetchLdapAttributes.sh $ENM_URL
if [[ $? -ne 0 ]]
then
 echo "LDAP Attribute fetching failed"
 exit 1
fi
else
echo "Skipping Fetching LDAP Attributes"
fi


PPWD=$(pwd)
Cmd="$PPWD/updateLdapAttributesOnNodesVM.sh"

IFS=' , ' read -r -a array <<< "$ServerName"

for server in "${array[@]}"
do 
      if [[ $server == *"|"* ]]; then
      echo "server is $server"
     serverName=`echo $server | awk -F "|" '{print $2}' | grep -v "\""`
     echo "**************************************************************************************************************"
     echo "serverName is $serverName"
     echo "**************************************************************************************************************"
   else
      echo "**************************************************************************************************************"
      serverName=$server
     echo "serverName is $serverName"
     echo "**************************************************************************************************************"
      fi
 if [[ $serverName == *"ieatnetsim"* ]]; then
     /usr/bin/expect <<EOF
     set timeout -1
     spawn scp -rp -o StrictHostKeyChecking=no /var/tmp/LdapAttributes.log netsim@$serverName.athtem.eei.ericsson.se:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
     spawn scp -rp -o StrictHostKeyChecking=no $Cmd netsim@$serverName.athtem.eei.ericsson.se:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     spawn scp -rp -o StrictHostKeyChecking=no $GET_JQ_TAR netsim@$serverName.athtem.eei.ericsson.se:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }

     sleep 5
     spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName.athtem.eei.ericsson.se "chmod 777 /netsim/updateLdapAttributesOnNodesVM.sh ; /netsim/updateLdapAttributesOnNodesVM.sh $ConfigType $Number_Of_BSC_Nodes $Number_Of_LTE_Nodes $TlsMode $AuthenticationDelay"
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
         spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName.athtem.eei.ericsson.se "rm -rf /netsim/updateLdapAttributesOnNodesVM.sh"
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
EOF
else
  /usr/bin/expect <<EOF
     set timeout -1
     spawn scp -rp -o StrictHostKeyChecking=no /var/tmp/LdapAttributes.log netsim@$serverName:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
     spawn scp -rp -o StrictHostKeyChecking=no $Cmd netsim@$serverName:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     spawn scp -rp -o StrictHostKeyChecking=no $GET_JQ_TAR netsim@$serverName:/netsim/
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }

     sleep 5
     spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName "chmod 777 /netsim/updateLdapAttributesOnNodesVM.sh ; /netsim/updateLdapAttributesOnNodesVM.sh $ConfigType $Number_Of_BSC_Nodes $Number_Of_LTE_Nodes $TlsMode $AuthenticationDelay"
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
         spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName "rm -rf /netsim/updateLdapAttributesOnNodesVM.sh"
     expect {
     -re assword: {send "netsim\r";exp_continue}
     }
     sleep 5
EOF
fi
 
done

OUTPUT=`cat /var/tmp/LdapAttributes.log | grep "Executed Successfully"`

if [ ! -z "$OUTPUT" -a "$OUTPUT"!=" " ]; then
    echo "Successfully updated"
else
    echo "Not a proper file."
    exit 1
fi
