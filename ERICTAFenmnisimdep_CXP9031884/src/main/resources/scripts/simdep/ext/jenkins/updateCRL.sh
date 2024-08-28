#!/bin/bash

if [[ $# -ne 3 ]]
then
	echo "ERROR: Invalid parameters"
	echo "Syntax: $0 DeploymentType DeploymentId ENM_GUI_LINK"
	exit 1
fi

deploymentType=$1
clusterId=$2
ENM_URL=$3
dirSimNetDeployer="/var/tmp/Certs";
crlUpdateLog="/var/tmp/crlUpdate.log";
NETSIM_SERVER_DETAILS_FILE="/var/tmp/NetsimserverDetailsForCRL.txt"

rm -rf $crlUpdateLog
rm -rf $NETSIM_SERVER_DETAILS_FILE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $NETSIM_SERVER_DETAILS_FILE failed"
    exit 201
fi
if [[ -f ${dirSimNetDeployer}/s_cacert.crl ]]
then
   rm -rf ${dirSimNetDeployer}/s_cacert.crl
   if [[ $? -ne 0 ]]
   then
     echo "ERROR: Removing ${dirSimNetDeployer}/s_cacert.crl failed"
     exit 201
   fi
fi

if [[ $deploymentType == "Cloud" ]] || [[ $deploymentType == "cloud" ]] ; then
    cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
    NetsimId=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$clusterId" | ./jq '.[].documents[]|select(.["schema_name"]=="netsim")|.document_id' | sed 's/\"//g'`
    NETSIMS=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$NetsimId" | ./jq '.content.vm[] | select(.active==true)|.ip' | sed 's/\"//g' | sort`; z=1; for i in $NETSIMS ; do echo server_$z $i >> $NETSIM_SERVER_DETAILS_FILE; ((z++)) ; done
	netsim_server=$(cat $NETSIM_SERVER_DETAILS_FILE | head -n 1 | awk -F " " '{print $2}')
else
	cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
    NETSIMS=`wget -q -O - --no-check-certificate "https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=$clusterId&tunnel=true" | ./jq '.[] |select(.hostname|contains("ieatnetsimv"))|.ip' | sed 's/\"//g' | sort` ; echo "******printing netsims " ; echo $NETSIMS ;z=1 ; for i in $NETSIMS ; do echo server_$z $i >> $NETSIM_SERVER_DETAILS_FILE; ((z++)) ; done
    netsim_server=$(cat $NETSIM_SERVER_DETAILS_FILE | head -n 1 | awk -F " " '{print $2}')
fi	

echo -e "INFO: Executing below command to create certs directory on ${netsim_server} server\n"

echo -e "sshpass -p netsim ssh -o StrictHostKeyChecking=no netsim@${netsim_server} \"if [[ -d /netsim/certs/ ]];then rm -rf /netsim/certs;if [[ $? -ne 0 ]];then echo 'ERROR: Removing certs directory failed trying to create again';rm -rf /netsim/certs/;if [[ $? -ne 0 ]];    then echo 'ERROR: Removing certs directory failed after retry';exit 1;fi;fi;fi;mkdir /netsim/certs;if [[ $? -ne 0 ]];then echo 'ERROR: Creating certs directory failed trying to create again';mkdir /netsim/certs;if [[ $? -ne 0 ]];then       echo 'ERROR: Creating certs directory failed after retry';exit 1;fi;fi\"\n\n"

sshpass -p netsim ssh -o StrictHostKeyChecking=no netsim@${netsim_server} "if [[ -d /netsim/certs/ ]];then rm -rf /netsim/certs;if [[ $? -ne 0 ]];then echo 'ERROR: Removing certs directory failed trying to create again';rm -rf /netsim/certs/;if [[ $? -ne 0 ]];	then echo 'ERROR: Removing certs directory failed after retry';exit 1;fi;fi;fi;mkdir /netsim/certs;if [[ $? -ne 0 ]];then echo 'ERROR: Creating certs directory failed trying to create again';mkdir /netsim/certs;if [[ $? -ne 0 ]];then 	echo 'ERROR: Creating certs directory failed after retry';exit 1;fi;fi" > ${WORKSPACE}/cmdOutput.txt

outputStatus=`cat ${WORKSPACE}/cmdOutput.txt | grep 'ERROR'`

if [[ ! -z $outputStatus ]]
then
   echo -e "ERROR: Few commands execution failed\n"
   cat ${WORKSPACE}/cmdOutput.txt
   exit 1
fi

echo -e "INFO: Copying NSSCA.key s_cacert.pem crlopenssl.cnf files to ${netsim_server} server\n"

curl --retry 5 -k -fsS -T ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/NSSCA.key -u netsim:netsim scp://${netsim_server}/netsim/certs/

curl --retry 5 -k -fsS -T ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/s_cacert.pem -u netsim:netsim scp://${netsim_server}/netsim/certs/

curl --retry 5 -k -fsS -T ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/crlopenssl.cnf -u netsim:netsim scp://${netsim_server}/netsim/certs/

echo -e "INFO: Executing below command to create denpendcy files and generate crl file\n"

echo -e "sshpass -p netsim ssh -o StrictHostKeyChecking=no netsim@${netsim_server} \"mkdir /netsim/certs/demoCA;if [[ $? -ne 0 ]];then echo 'ERROR: Creating demoCA directory failed trying to create again';mkdir ;if [[ $? -ne 0 ]];then echo 'ERROR: Creating demoCA directory failed even after retry';exit 1;fi;fi;touch /netsim/certs/demoCA/index.txt;if [[ $? -ne 0 ]];then echo 'ERROR: Creating index.txt file failed retrying';touch /netsim/certs/demoCA/index.txt;if [[ $? -ne 0 ]];then echo 'ERROR: Creating index.txt file failed even after retrying';exit 1;fi;fi;touch /netsim/certs/demoCA/crlnumber;if [[ $? -ne 0 ]];then echo 'ERROR: Creating crlnumber file failed retrying';touch /netsim/certs/demoCA/crlnumber;if [[ $? -ne 0 ]];then echo 'ERROR: Creating crlnumber file failed even after retrying';exit 1;fi;fi;echo 1000 > /netsim/certs/demoCA/crlnumber; if [[ $? -ne 0 ]];then echo 'ERROR: Editing crlnumber file failed';exit 1;fi;cd /netsim/certs/;if [[ $? -ne 0 ]];then echo -e 'ERROR: Unable to move to /netsim/certs/ folder retrying';cd /netsim/certs;if [[ $? -ne 0 ]];then echo 'ERROR: Unable to move to /netsim/certs/ folder even after retry';fi;fi;openssl ca -config crlopenssl.cnf -gencrl -keyfile NSSCA.key -cert s_cacert.pem -out s_cacert.crl; if [[ -f /netsim/certs/s_cacert.crl && -s /netsim/certs/s_cacert.crl ]];then echo 'INFO: CRL file generation was successfull';else echo 'ERROR: CRL file generation failed';exit 1;fi\"\n\n"

sshpass -p netsim ssh -o StrictHostKeyChecking=no netsim@${netsim_server} "mkdir /netsim/certs/demoCA;if [[ $? -ne 0 ]];then echo 'ERROR: Creating demoCA directory failed trying to create again';mkdir ;if [[ $? -ne 0 ]];then echo 'ERROR: Creating demoCA directory failed even after retry';exit 1;fi;fi;touch /netsim/certs/demoCA/index.txt;if [[ $? -ne 0 ]];then echo 'ERROR: Creating index.txt file failed retrying';touch /netsim/certs/demoCA/index.txt;if [[ $? -ne 0 ]];then echo 'ERROR: Creating index.txt file failed even after retrying';exit 1;fi;fi;touch /netsim/certs/demoCA/crlnumber;if [[ $? -ne 0 ]];then echo 'ERROR: Creating crlnumber file failed retrying';touch /netsim/certs/demoCA/crlnumber;if [[ $? -ne 0 ]];then echo 'ERROR: Creating crlnumber file failed even after retrying';exit 1;fi;fi;echo 1000 > /netsim/certs/demoCA/crlnumber; if [[ $? -ne 0 ]];then echo 'ERROR: Editing crlnumber file failed';exit 1;fi;cd /netsim/certs/;if [[ $? -ne 0 ]];then echo -e 'ERROR: Unable to move to /netsim/certs/ folder retrying';cd /netsim/certs;if [[ $? -ne 0 ]];then echo 'ERROR: Unable to move to /netsim/certs/ folder even after retry';fi;fi;openssl ca -config crlopenssl.cnf -gencrl -keyfile NSSCA.key -cert s_cacert.pem -out s_cacert.crl; if [[ -f /netsim/certs/s_cacert.crl && -s /netsim/certs/s_cacert.crl ]];then echo 'INFO: CRL file generation was successfull';else echo 'ERROR: CRL file generation failed';exit 1;fi" > ${WORKSPACE}/cmdOutput.txt

outputStatus=`cat ${WORKSPACE}/cmdOutput.txt | grep 'ERROR'`

if [[ ! -z $outputStatus ]]
then
   echo "ERROR: Few commands execution failed"
   cat ${WORKSPACE}/cmdOutput.txt
   exit 1
fi
echo -e "INFO: Copying crl file from ${netsim_server} to workspace\n"

/usr/bin/expect <<EOF
	set timeout -1
    spawn scp -rp -o StrictHostKeyChecking=no netsim@${netsim_server}:/netsim/certs/s_cacert.crl ${dirSimNetDeployer}/
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
EOF

echo -e "INFO: Updating nss cert with crl\n"
/var/tmp/runCliCommand.py 'pkiadm extcaupdatecrl -fn file:s_cacert.crl --name "ENM_ExtCA3"' $ENM_URL $dirSimNetDeployer/s_cacert.crl >> $crlUpdateLog
