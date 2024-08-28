#!/bin/bash
###################################################################################
#     File Name    : reApplyTLS.sh
#     Version      : 4.00
#     Author       : Sneha Srivatsav Arra, Fatih ONUR, edalrey
#     Description  : Re applies Certs after every initial installation
#     Date Created : 10 May 2016
###################################################################################
trap onError INT TERM EXIT
set -o nounset  # will exit the script if an uninitialised variable is used.
set -o errexit  # will exit the script if any statement returns a non-true return value.
set -o pipefail # will take the error status of any item in a pipeline.

###################################################################################
#   Functions
###################################################################################
function help {
    cat << EOF

    HELP:
        Used to reapply TLS certs after initial installation of ENM for vFarm and vApp servers.
        If no NETSim hosts are specified, all available NETSim hosts on CI Portal (DMT) will be used.

    Usage:
        $0 -n <NSS_RELEASE> -s <SIMDEP_RELEASE> -t <SERVER_TYPE> -i <ID_FOR_SERVER> (-h <NETSIM_HOSTS>)

        where madatory parameters are
            <NSS_RELEASE>   : Release version of NSS Drop
            <SIMDEP_RELEASE>: Release version of SimDep
            <SERVER_TYPE>   : Binary value: VM | VAPP
            <ID_FOR_SERVER> : Deployment number (as per DMT); or vApp name (as per cloud)

        where optional parameters are
            <NETSIM_HOSTS>  : Space-separated list of netsim hosts

    Usage examples:
        $0 -n 16.7 -s 1.5.55 -t VM   -i 227
        $0 -n 16.7 -s 1.5.55 -t VM   -i 227       -h "ieatnetsimv5022-01"
        $0 -n 16.7 -s 1.5.55 -t VM   -i 421       -h "ieatnetsimv5056-01 ieatnetsimv5056-02 ieatnetsimv5056-03"
        $0 -n 16.7 -s 1.5.55 -t VAPP -i atvts2821


    Return values:
        (Success)    \$simdepStatus == ONLINE,  exit -> 0
        (Failure)    \$simdepStatus == OFFLINE, exit -> 1
EOF
    exit 202
}
function checkArgs {
    if [[ -z  $NSS_RELEASE ]]
    then
        help
    fi
    if [[ -z $SIMDEP_RELEASE ]]
    then
        help
    fi
    if [[ -z $SERVER_TYPE ]]
    then
        help
    fi
    if [[ -z $ID_FOR_SERVER ]]
    then
        help
    fi
}
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
function valid_ip {
    local ip=$1
    local stat=1;
    matchingIp=`echo $ip | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
    if [[ -z $matchingIp ]]
    then
        stat=1
    else
        stat=0
    fi
    echo $stat
}
function getManagementServerFromClusterInfo {
    clusterInfo=$1

    managementServer=$(echo "$clusterInfo" |  python -c "exec(\"import json,sys\\nobj=json.load(sys.stdin)\\nip='dummy'\\nfor serv in obj: print(serv['ip']) if serv['hostname'] == 'ms1' else ''\")")
    validated=`valid_ip $managementServer`

    if [[ $validated -ne 0 ]]
    then
        echo "[ERROR] Managment server ($managementServer) is not a valid IP address" 1>&2
        exit 1
    fi

    echo "$managementServer"
}

###################################################################################
#   Input parameters
###################################################################################
while getopts "n:s:t:i:h:" arg
do
    case "$arg" in
        n)  NSS_RELEASE=$OPTARG;;
        s)  SIMDEP_RELEASE=$OPTARG;;
        t)  SERVER_TYPE=$OPTARG;;
        i)  ID_FOR_SERVER=$OPTARG;;
        h)  NETSIM_HOSTS=$OPTARG;;
        \?) help;;
    esac
done
checkArgs

###################################################################################
#   Local variables
###################################################################################
setupSecurityScript=setupSecurityTLS.sh
simdepPath=ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/
simdepJar=ERICTAFenmnisimdep_CXP9031884-${SIMDEP_RELEASE}.jar

###################################################################################
#   Main
###################################################################################
echo "Executing $0 $@"
echo "on host: `hostname`"
echo "by user: `whoami`"

#############################################################
#   Finding Management/Gateway Server details for a given cluster/vApp Id.
#############################################################
if [[ $SERVER_TYPE = VM ]]
then
    clusterInfo=`wget -q -O - --no-check-certificate "https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=${ID_FOR_SERVER}&tunnel=true"`
    managementServer=$(getManagementServerFromClusterInfo "$clusterInfo")
    echo "managementServer_ip: $managementServer"
    echo "managementServer_name: `nslookup $managementServer | perl -ne 'if (/name =/){/.*=.(.*)./i;print $1 . "\n"}'`"
    PORT=22

    if [[ -z $NETSIM_HOSTS ]]
    then
        echo "Getting NETSim host names from CI Portal"
        hostNames=`echo "$clusterInfo" | grep -o "\w*ieatnetsim\w*-\w*"`
    else
        echo "Using NETSim host names from input parameter"
        hostNames=$NETSIM_HOSTS
    fi
    echo "NETSim host names are: $hostNames"
elif [[ $SERVER_TYPE = VAPP ]]
then
    # A cluster ID of '239' is specific to all vApps.
    clusterInfo=`wget -q -O - --no-check-certificate "https://ci-portal.seli.wh.rnd.internal.ericsson.com/generateTAFHostPropertiesJSON/?clusterId=239&tunnel=true"`
    managementServer=$(getManagementServerFromClusterInfo "$clusterInfo")
    echo "managementServer_ip: $managementServer"
    echo "managementServer_name: `nslookup $managementServer | perl -ne 'if (/name =/){/.*=.(.*)./i;print $1 . "\n"}'`"
    PORT=2202

    hostNames=$ID_FOR_SERVER
    echo "vApp host name is: $hostNames"
else
    echo "'$SERVER_TYPE' is not a valid SERVER_TYPE value."
    help
fi
if [[ -z $hostNames ]]
then
    echo "[ERROR] No hosts have been selected for Security Cert reapplication."
    exit 1
fi

#######################################################
#   Looping over every NETSim box to reapply certs
#######################################################
for hostName in $hostNames
do
     echo "########################################################################################"
     echo "#    Server Name:    $hostName"
     echo "########################################################################################"

    tempFileName=simdepStatus$hostName.txt
    tempFilePath=/tmp/$tempFileName

    echo "[INFO] Copying the release version of enm-ni-simdep-testware from jenkins:`hostname` to ${hostName}:/netsim"
    /usr/bin/expect  <<EOF
    spawn scp -rp -o StrictHostKeyChecking=no -P $PORT $simdepJar netsim@$hostName.athtem.eei.ericsson.se:/netsim/
    expect {
        -re assword: {send "netsim\r";exp_continue}
    }
    sleep 5
EOF

    echo "[INFO] Copying $setupSecurityScript from jenkins:`hostname` to ${hostName}:/netsim/"
    /usr/bin/expect  <<EOF
    spawn scp -rp -o StrictHostKeyChecking=no -P $PORT $simdepPath$setupSecurityScript root@$hostName.athtem.eei.ericsson.se:/netsim
    expect {
        -re assword: {send "shroot\r";exp_continue}
    }
    sleep 5
EOF

    echo "[INFO] Running $setupSecurityScript"
    /usr/bin/expect <<EOF
    set timeout -1
    spawn ssh -o StrictHostKeyChecking=no -p $PORT root@$hostName.athtem.eei.ericsson.se /netsim/$setupSecurityScript -n $NSS_RELEASE -s $SIMDEP_RELEASE -h $hostName -t $SERVER_TYPE -m $managementServer -p $tempFilePath
    expect {
        -re assword: {send "shroot\r";exp_continue}
    }
    sleep 5
EOF

    echo "[INFO] Copying $tempFilePath from $hostName to Jenkins' workspace "
    /usr/bin/expect  << EOF
    spawn scp -o StrictHostKeyChecking=no -P $PORT root@$hostName.athtem.eei.ericsson.se:$tempFilePath $WORKSPACE
    expect {
        -re Password: {send "shroot\r";}
    }
    sleep 5
EOF

    simdepStatus=`cat $WORKSPACE/$tempFileName`
    printf "\n[INFO] SimDep status is $simdepStatus \n"

    if [[ "$simdepStatus" != ONLINE ]]
    then
        echo "[ERROR] Failed to apply TLS Certs for $hostName"
        exit 1
    fi
done

#######################################################
#   End
#######################################################
