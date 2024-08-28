#!/bin/bash
###################################################################################
#     File Name    : setupSecuritySL2.sh
#     Version      : 1.00
#     Author       : Fatih ONUR
#     Description  : Re applies Certs after every initial installation
#     Date Created : 22 June 2016
###################################################################################
trap onError EXIT
set -o nounset  # will exit the script if an uninitialised variable is used.
set -o errexit  # will exit the script if any statement returns a non-true return value.
set -o pipefail # will take the error status of any item in a pipeline.

###################################################################################
#   Functions
###################################################################################
function help {
    cat << EOF

    HELP:
        Used to reapply security certs after initial installation of ENM.

    Usage:
        $0 -n <NSS_RELEASE> -s <SIMDEP_RELEASE> -h <HOST_NAME> -t <SERVER_TYPE> -m <MANAGEMENT_SERVER> -p <TEMP_FILE_PATH>

        where madatory parameters are
            <NSS_RELEASE>       : Release version of NSS Drop
            <SIMDEP_RELEASE>    : Release version of SimDep
            <HOST_NAME>         : Name of the host server
            <SERVER_TYPE>       : Binary value[Not inforced]: VM | VAPP
            <MANAGEMENT_SERVER> : Address of ENM management server
            <TEMP_FILE_PATH>    : NETSim host's tmp directory for temporary file storage

    usage examples:
        $0 -n 16.7 -s 1.5.55 -h ieatnetsimv5022-01 -t VM   -m 141.137.248.133 -p /tmp/LTE/simNetDeployer/16.7/
        $0 -n 16.9 -s 1.5.55 -h atvts2821          -t VAPP -m 141.137.248.133 -p /tmp/LTE/simNetDeployer/16.9/


    Return values:
        (Success)   exit 0   -> \$simdepStatus == ONLINE
        (Failure)   exit 1   -> \$simdepStatus == OFFLINE
                    exit 212 -> Node(s) not started; \$simdepStatus == OFFLINE
EOF
    exit 202
}
nexusLink="https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/"
function checkArgs {
    if [[ -z $NSS_RELEASE ]]
    then
        help
    fi
    if [[ -z $SIMDEP_RELEASE ]]
    then
        help
    fi
    if [[ -z $HOST_NAME ]]
    then
        help
    fi
    if [[ -z $SERVER_TYPE ]]
    then
        help
    fi
    if [[ -z $MANAGEMENT_SERVER ]]
    then
        help
    fi
    if [[ -z $TEMP_FILE_PATH ]]
    then
        help
    fi
}
function catchError {
    if [[ $? -ne 0 ]]
    then
        echo "$1"
        echo "OFFLINE" > $TEMP_FILE_PATH
        exit 1
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

###################################################################################
#   Input parameters
###################################################################################
while getopts "n:s:h:t:m:p:" arg
do
    case "$arg" in
        n)  NSS_RELEASE=$OPTARG ;;
        s)  SIMDEP_RELEASE=$OPTARG ;;
        h)  HOST_NAME=$OPTARG ;;
        t)  SERVER_TYPE=$OPTARG ;;
        m)  MANAGEMENT_SERVER=$OPTARG ;;
        p)  TEMP_FILE_PATH=$OPTARG ;;
        \?) help ;;
    esac
done
checkArgs

###################################################################################
#   Local variables
###################################################################################
workingPath=/tmp/LTE/simNetDeployer/$NSS_RELEASE/
switchToEnm=yes
reapplyCerts=YES
vappNodesStartedPerSim=5
simdepUnzipPath=/netsim/sl2/enm-ni-simdep/

###################################################################################
#   Main
###################################################################################

echo "[INFO] Setting script success status"
echo "OFFLINE" > /tmp/simdepStatus$HOST_NAME.txt

echo "[INFO] Removing $simdepUnzipPath directory"
su - netsim -c "rm -rf $simdepUnzipPath";
catchError "ERROR: Failed to remove $simdepUnzipPath"

echo "[INFO] Creating $simdepUnzipPath"
su - netsim -c "mkdir -p $simdepUnzipPath";
catchError "ERROR: Failed to create $simdepUnzipPath"

#echo "[INFO] Downloading the release version of enm-ni-simdep-testware from nexus"
#su - netsim -c "cd $simdepUnzipPath;
#wget ${nexusLink}content/repositories/releases/com/ericsson/ci/simnet/ERICTAFenmnisimdep_CXP9031884/${SIMDEP_RELEASE}/ERICTAFenmnisimdep_CXP9031884-${SIMDEP_RELEASE}.jar";
#catchError "ERROR: Failed to download the release version of enm-ni-simdep-testware from nexus"
# switch above wget with the following line while testing the code
#wget ${nexusLink}content/repositories/snapshots/com/ericsson/ci/simnet/ERICTAFenmnisimdep_CXP9031884/1.5.74-SNAPSHOT/ERICTAFenmnisimdep_CXP9031884-${SIMDEP_RELEASE}.jar";

echo "[INFO] Unzipping the contents of ERICTAFenmnisimdep_CXP9031884-${SIMDEP_RELEASE}.jar file"
su - netsim -c "unzip ERICTAFenmnisimdep_CXP9031884-${SIMDEP_RELEASE}.jar -d $simdepUnzipPath";
catchError "ERROR: Failed to unzip the contents of ERICTAFenmnisimdep_CXP9031884-${SIMDEP_RELEASE}.jar file"

echo "[INFO] Changing the file permissions of $simdepUnzipPath directory"
su - netsim -c "chmod -R 777 $simdepUnzipPath;"
catchError "ERROR: Failed to change the file permissions of $simdepUnzipPath directory"

echo "[INFO] Converting simdep scripts from DOS to UNIX for correct formatting."
for script in `find ${simdepUnzipPath}scripts -print | egrep -i 'sh|pl|txt'` ;do /usr/bin/dos2unix $script;
catchError "ERROR: Failed to convert $script from dos to unix."
done

echo "[INFO] Changing the directory to ${simdepUnzipPath}scripts/simdep/bin"
cd ${simdepUnzipPath}scripts/simdep/bin
catchError "ERROR: Failed to change the directory to ${simdepUnzipPath}/scripts/simdep/bin"

echo "[INFO] Running ./invokeSimNetDeployer.pl -overwrite -createDirectories -release $NSS_RELEASE"
./invokeSimNetDeployer.pl -overwrite -createDirectories -release $NSS_RELEASE -simLTE "X" -simWRAN "" -simCORE ""  > /dev/null 2>&1;
catchError "ERROR: Failed to run invokeSimNetDeployer.pl script."

echo "[INFO] Running ./removeSL2.sh to remove Security certificates on the existing radio nodes."
su - netsim -c "cd ${workingPath}utils/; ./removeSL2.sh"
catchError "ERROR: Failed to run removeSL2.sh script."

ssh-keygen -R $MANAGEMENT_SERVER >/dev/null 2>&1

echo "[INFO] Turning SL2 ON"
confPath=${workingPath}conf/conf.txt
su - netsim -c "sed -i '/SETUP_SECURITY_SL2/c\SETUP_SECURITY_SL2=ON' $confPath"
catchError "ERROR: Failed to enable SL2 on."
su - netsim -c "sed -i '/SETUP_SECURITY_TLS/c\SETUP_SECURITY_TLS=OFF' $confPath"
catchError "ERROR: Failed to disable TLS off."


echo "[INFO] Re-applying Security Definition for CPP nodes"
netsimHostName=`hostname`
cd ${workingPath}bin/;
./setupSecurityMSTLS.pl $SERVER_TYPE $MANAGEMENT_SERVER root 12shroot $netsimHostName root shroot $workingPath $switchToEnm $reapplyCerts
catchError "ERROR: Failed to run setupSecurityMSTLS.pl script."

if [[ $SERVER_TYPE = VM ]]
then
    echo "[INFO] Checking for non-started nodes"
    expectedNonStartedNodes=0
    actualNonStartedNodes=`su - netsim -c "echo '.show allsimnes' | /netsim/inst/netsim_pipe | grep -i 'not started\|error' | wc -l"`
    if [[ $expectedNonStartedNodes -ne $actualNonStartedNodes ]]
    then
        echo "ERROR: $HOST_NAME contains $actualNonStartedNodes node(s) not in Started state."
        echo "`su - netsim -c "echo '.show allsimnes' | /netsim/inst/netsim_pipe | grep not"`"
        echo "OFFLINE" > $TEMP_FILE_PATH
        exit 212
    fi
    echo "[INFO] All nodes on $HOST_NAME are in Started state."
fi

echo "[INFO] Setting SimDep status ONLINE"
echo "ONLINE" > /tmp/simdepStatus$HOST_NAME.txt
catchError "ERROR: Failed to set ONLINE status. Defaulting to OFFLINE."

#######################################################
#   End
#######################################################
