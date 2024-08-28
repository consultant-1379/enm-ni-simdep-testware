#!/bin/bash

######################################################################################
#     File Name     : nodesCleanUp.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : Restores database for Skyfall and Abedhya used RadioNodes.
#     Date Created  : 20 July 2017
#######################################################################################
#
trap onError INT TERM EXIT
set -o nounset  # will exit the script if an uninitialised variable is used.
set -o errexit  # will exit the script if any statement returns a non-true return value.
set -o pipefail # will take the error status of any item in a pipeline.

function onError {
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: A pipeline command has failed at line:"
        n=0
        # The caller builtin command is used to print execution frames of subroutine calls.
        # The topmost execution frame information is printed ("who called me") with line number and filename.
        while caller $((n++)); do :; done;
    fi
}
##############################################
#Variable declarations
##############################################
clusterId=$1
Drop=$2
envType=$3
nexusLink="https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/"
NODES_INFO_FILE=/var/tmp/nodes.txt
NETSIM_SERVER_DETAILS_FILE=/var/tmp/NETSimServerdetails.txt
SERVER_SIMULATION_NODE_FILE=/var/tmp/ServerSimulationNodeDetails.txt
NETSIM_SERVER_FILE=/var/tmp/NETSimServers.txt
CLEAN_UP_NODE_CERTIFICATE=/var/tmp/cleanUpNodeCertificate.sh
CPP_CLEAN_UP_NODE_CERTIFICATE=/var/tmp/CppcleanUpNodeCertificate.sh
CPP_CLEAN_UP_CERTS_NODE_CERTIFICATE=/var/tmp/CppcleanUpCertsNodeCertificate.sh
CLEAN_UP_NODES_LOG=/var/tmp/cleanUpNodesLog.log
CPP_CLEAN_UP_NODES_LOG=/var/tmp/CppcleanUpNodesLog.log
CPP_CLEAN_UP_CERTS_NODES_LOG=/var/tmp/CppcleanUpCertsNodesLog.log
SIMULATION_DETAILS_FILE=/var/tmp/Simulation.txt
NODESSTARTEDCHECK_FILE=/var/tmp/NodesStartedCheck.txt
NODE_NAME_FILE=/var/tmp/NodeNames.txt
GET_SIM_DETAILS=${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/getSimDetails.sh
GET_JQ_TAR=${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar

rm -rf $NODES_INFO_FILE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $NODES_INFO_FILE failed"
    exit 201
fi
rm -rf $NETSIM_SERVER_DETAILS_FILE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $NETSIM_SERVER_DETAILS_FILE failed"
    exit 201
fi
rm -rf $SERVER_SIMULATION_NODE_FILE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $SERVER_SIMULATION_NODE_FILE failed"
    exit 201
fi
rm -rf $NETSIM_SERVER_FILE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $NETSIM_SERVER_FILE failed"
    exit 201
fi
rm -rf $CLEAN_UP_NODE_CERTIFICATE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $CLEAN_UP_NODE_CERTIFICATE failed"
    exit 201
fi
rm -rf $SIMULATION_DETAILS_FILE
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $SIMULATION_DETAILS_FILE failed"
    exit 201
fi

if [ $envType == "Cloud" ] ; then
    cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
    NetsimId=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/deployments/?q=name=$clusterId" | ./jq '.[].documents[]|select(.["schema_name"]=="netsim")|.document_id' | sed 's/\"//g'`
    NETSIMS=`curl -s "http://atvdit.athtem.eei.ericsson.se/api/documents/$NetsimId" | ./jq '.content.vm[] | select(.active==true)|.ip' | sed 's/\"//g' | sort`; z=1; for i in $NETSIMS ; do echo server_$z $i >> $NETSIM_SERVER_DETAILS_FILE; ((z++)) ; done
	netsim_server=$(cat $NETSIM_SERVER_DETAILS_FILE | head -n 1 | awk -F " " '{print $2}')
	/usr/bin/expect <<EOF
	set timeout -1
    spawn scp -rp -o StrictHostKeyChecking=no netsim@$netsim_server:/netsim/simdepContents/NRMSize.content .
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
EOF
    nrmDef=$(cat NRMSize.content)
	if [[ $nrmDef =~ "\"medium (15k)\"" ]]; then
		nwFile="${Drop}_nw_layout_15k_vfarm.txt"
		csvFile="nodeToAdd_15K.csv"
	else
		nwFile="${Drop}_nw_layout_nssModule_RFA250_vfarm.txt"
		csvFile="nodeToAdd_2K.csv"
	fi
    /usr/bin/curl -O "${nexusLink}content/sites/tor/enm-maintrack-central-test-datasource/latest/maintrack/csv/$csvFile"
else
	cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/bin/netsim/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq
    NETSIMS=`wget -q -O - --no-check-certificate "https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=$clusterId&tunnel=true" | ./jq '.[] |select(.hostname|contains("ieatnetsimv"))|.ip' | sed 's/\"//g' | sort` ; echo "******printing netsims " ; echo $NETSIMS ;z=1 ; for i in $NETSIMS ; do echo server_$z $i >> $NETSIM_SERVER_DETAILS_FILE; ((z++)) ; done
    #if [[ -z $NETSIMS ]]
    #then
     #  NETSIMS=`wget -q -O - --no-check-certificate "https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=$clusterId&tunnel=true" | grep -oh "\w*ieatnetsim\w*-\w*" | sort` ; z=1 ; for i in $NETSIMS ; do echo server_$z $i >> $NETSIM_SERVER_DETAILS_FILE; ((z++)) ; done
    #fi
	netsim_server=$(cat $NETSIM_SERVER_DETAILS_FILE | head -n 1 | awk -F " " '{print $2}')
	/usr/bin/expect <<EOF
	set timeout -1
    spawn scp -rp -o StrictHostKeyChecking=no netsim@$netsim_server:/netsim/simdepContents/NRMSize.content .
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
EOF
    nrmDef=$(cat NRMSize.content)
	if [[ $nrmDef =~ "\"medium (15k)\""  ]]; then
		nwFile="${Drop}_nw_layout_15k_vfarm.txt"
		csvFile="nodeToAdd_15K.csv"
	else
		nwFile="${Drop}_nw_layout_nssModule_RFA250_vfarm.txt"
		csvFile="nodeToAdd_2K.csv"
	fi
    /usr/bin/curl -O "${nexusLink}content/sites/tor/enm-maintrack-central-test-datasource/latest/maintrack/csv/$csvFile"
fi


if [[ $? -ne 0 ]]
then
    echo "ERROR: Downloading $csvFile failed."
    exit 201
fi

cat $csvFile | grep  ",nc_yes" | grep -v "CPP" | awk -F "," '{ printf "%s %s\n", $7, "RadioNode" }' | sort --unique > $NODES_INFO_FILE

cat $csvFile | grep  ",nc_yes" | grep  "CPP" | awk -F "," '{ printf "%s %s\n", $7, "ERBS" }' | sort --unique >> $NODES_INFO_FILE

cat $NETSIM_SERVER_DETAILS_FILE | awk '{print $2}' | sort | uniq > $NETSIM_SERVER_FILE


for serverName in `cat $NETSIM_SERVER_FILE`
do
    /usr/bin/expect <<EOF
    set timeout -1
     spawn scp -rp -o StrictHostKeyChecking=no $GET_JQ_TAR netsim@$serverName:/var/tmp/jq-1.0.1.tar
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
        spawn scp -rp -o StrictHostKeyChecking=no $GET_SIM_DETAILS netsim@$serverName:/var/tmp/getSimDetails.sh
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
	spawn scp -rp -o StrictHostKeyChecking=no $NODES_INFO_FILE netsim@$serverName:/var/tmp/
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
    spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName "sh /var/tmp/getSimDetails.sh $NODES_INFO_FILE"
    expect {
       -re assword: {send "netsim\r";exp_continue}
    }
	spawn scp -rp -o StrictHostKeyChecking=no netsim@$serverName:/var/tmp/$serverName /var/tmp/$serverName
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
EOF
done

for serverName in `cat $NETSIM_SERVER_FILE`
do
  cat /var/tmp/$serverName >> $SERVER_SIMULATION_NODE_FILE
done

echo -e '#!/bin/sh \nNETSIM_INST=/netsim/inst \nls -1 /netsim/netsimdir/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" | grep -v -E "^default$" | grep $1 > $NETSIM_INST/TlsCertSim.log \nfor i in `cat $NETSIM_INST/TlsCertSim.log` \n do \n echo -e ".open $i \n .select $2 \n .stop \n .restorenedatabase curr all force \n .start" | $NETSIM_INST/netsim_shell >> /var/tmp/cleanUpNodesLog.log \n done' > $CLEAN_UP_NODE_CERTIFICATE

echo -e '#!/bin/sh \nInstpath=/netsim/inst \nls -1 /netsim/netsimdir/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" | grep -v -E "^default$" | grep $1 > $Instpath/TlsCertSim.log \nfor i in `cat $Instpath/TlsCertSim.log` \n do \n echo -e ".open $i \n .select $2 \n .start \n oseshell \n secmode -l 1" | $Instpath/netsim_shell >> /var/tmp/CppcleanUpNodesLog.log \n done' > $CPP_CLEAN_UP_NODE_CERTIFICATE

echo -e '#!/bin/sh \nInstpath=/netsim/inst \nls -1 /netsim/netsimdir/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" | grep -v -E "^default$" | grep $1 > $Instpath/TlsCertSim.log \nfor i in `cat $Instpath/TlsCertSim.log` \n do \n echo -e ".open $i \n .select $2 \n.stop \n .restorenedatabase curr all force \n .start" | $Instpath/netsim_shell >> /var/tmp/CppcleanUpCertsNodesLog.log \n done' > $CPP_CLEAN_UP_CERTS_NODE_CERTIFICATE

for serverName in `cat $NETSIM_SERVER_FILE`
do
    /usr/bin/expect <<EOF
    set timeout -1
    spawn scp -rp -o StrictHostKeyChecking=no $CLEAN_UP_NODE_CERTIFICATE netsim@$serverName:/var/tmp/
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    sleep 2
    spawn scp -rp -o StrictHostKeyChecking=no $CPP_CLEAN_UP_NODE_CERTIFICATE netsim@$serverName:/var/tmp/
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }
    spawn scp -rp -o StrictHostKeyChecking=no $CPP_CLEAN_UP_CERTS_NODE_CERTIFICATE netsim@$serverName:/var/tmp/
        expect {
           -re assword: {send "netsim\r";exp_continue}
        }   
    sleep 2
    spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName "rm -rf $CLEAN_UP_NODES_LOG"
    expect {
       -re assword: {send "netsim\r";exp_continue}
    }
    spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName "rm -rf $CPP_CLEAN_UP_NODES_LOG"
    expect {
       -re assword: {send "netsim\r";exp_continue}
    }
    spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName "rm -rf $CPP_CLEAN_UP_CERTS_NODES_LOG"
    expect {
       -re assword: {send "netsim\r";exp_continue}
    }
EOF
done

while read ServerName SimulationName NodeName NodeType
do
 if [ $NodeType == "RadioNode" ] ; then
  Cmd="sh $CLEAN_UP_NODE_CERTIFICATE $SimulationName $NodeName"
 else
  Cmd="sh $CPP_CLEAN_UP_NODE_CERTIFICATE $SimulationName $NodeName"
 fi
    echo $Cmd
    /usr/bin/expect <<EOF
    set timeout -1
    spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$ServerName $Cmd
        expect {
            -re assword: {send "netsim\r";exp_continue}
        }
        sleep 2
EOF
done < $SERVER_SIMULATION_NODE_FILE

while read ServerName SimulationName NodeName NodeType
do
 if [ $NodeType == "ERBS" ] ; then
  Cmd="sh $CPP_CLEAN_UP_CERTS_NODE_CERTIFICATE $SimulationName $NodeName"
  echo $Cmd
  /usr/bin/expect <<EOF
  set timeout -1
  spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$ServerName $Cmd
    expect {
        -re assword: {send "netsim\r";exp_continue}
      }
      sleep 2
EOF
fi
done < $SERVER_SIMULATION_NODE_FILE

echo "sleeping for 5 minutes"
sleep 5m

ACTUAL_COUNT=0
for serverName in `cat $NETSIM_SERVER_FILE`
do
Cmd="echo -e '.show allsimnes' | /netsim/inst/netsim_shell | grep 'not started' > $NODESSTARTEDCHECK_FILE"
/usr/bin/expect <<EOF
    set timeout -1
    spawn ssh -o StrictHostKeyChecking=no -p 22 netsim@$serverName $Cmd
        expect {
            -re assword: {send "netsim\r";exp_continue}
        }
 sleep 1
 spawn scp -rp -o StrictHostKeyChecking=no netsim@$serverName:$NODESSTARTEDCHECK_FILE /var/tmp/$serverName.log
        expect {
            -re assword: {send "netsim\r";exp_continue}
        }
EOF
done
for serverName in `cat $NETSIM_SERVER_FILE`
do
 NotStartedNodes=`cat /var/tmp/$serverName.log | wc -l`
 if [[ $NotStartedNodes -eq 0 ]] ; then
  echo "All nodes are started in server $serverName"
 else
	 echo "Some nodes are not in started in server $serverName"
  ACTUAL_COUNT=`expr "$ACTUAL_COUNT" + 1`
 fi
done

if [[ $ACTUAL_COUNT -eq 0 ]] ; then
    echo "INFO: Nodes Clean Up is successfully completed."
else
    echo "ERROR: There is some error while cleaning few nodes. Kindly please check"
    exit 1
fi  
