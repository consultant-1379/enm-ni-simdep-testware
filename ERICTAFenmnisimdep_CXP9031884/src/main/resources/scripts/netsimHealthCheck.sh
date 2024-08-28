#!/bin/bash
#
##############################################################################
#     File Name     : netsimHealthCheck.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : Verifies if netsim box is in healthy state after rollout
#     Date Created  : 15 June 2017
###############################################################################
usage() {
echo "usage: ./netsimHealthCheck securityTLS securitySL2 nssdrop installation_Type"
echo "example: ./netsimHealthCheck on off 21.06 online"
echo "example: ./netsimHealthCheck on on 21.06 offline"
}
if [ $# -ne 4 ]
then
usage
exit 1
fi
########################################################
#Verification if start_all_simne script is present
########################################################
STARTSIMNE_SCRIPT="/netsim/inst/bin/start_all_simne.sh"
if [ ! -f $STARTSIMNE_SCRIPT ]
then
    if [[ ${install_Type} = "offline" ]]
    then
        echo "INFO: Copying start_all_simne.sh script"
        cp /netsim/Extra/start_all_simne.sh /netsim/inst/bin/start_all_simne.sh
    else
        echo "INFO: Copying start_all_simne.sh script"
        cp /var/simnet/enm-ni-simdep/scripts/start_all_simne.sh /netsim/inst/bin/start_all_simne.sh
    fi
    chmod 777 -R /netsim/inst/bin/start_all_simne.sh
fi

SIMDEP_CONTENT="/netsim/simdepContents"
network_type=`ls $SIMDEP_CONTENT | grep Simnet_.*.content | cut -d'_' -f 3`
su - netsim -c "echo '.show simulations' | /netsim/inst/netsim_shell"
if [[ $? -ne 0 ]]
then 
    su - netsim -c '/netsim/inst/restart_netsim'
    if [ "$network_type" != "8K" ] 
    then
        su - netsim -c '/netsim/inst/bin/start_all_simne.sh | /netsim/inst/netsim_shell'
    else
        echo "[WARN]: Skipping Start Nodes  for 1.8K"
    fi
fi
###################################################################
#Variables
###################################################################
SIMDEP_CONTENTS="/netsim/simdepContents"
securityTLS=`echo $1 | tr '[A-Z]' '[a-z]'`
securitySL2=`echo $2 | tr '[A-Z]' '[a-z]'`
drop=`echo $3 | tr '.' '-'`
install_Type=$4
####################################################################
#Verification of NETSim version
####################################################################

NETSIM_VERSION_FROM_PORTAL=`cat $SIMDEP_CONTENTS/netsimVersionFromPortal`

NETSIM_VERSION_INSTALLED=`cat /netsim/inst/release.erlang`

NETSIM_VERSION_INSTALLED=${NETSIM_VERSION_INSTALLED:(-5)}

NETSIM_VERSION_INSTALLED=${NETSIM_VERSION_INSTALLED%?}

if [[ "$NETSIM_VERSION_INSTALLED" == "$NETSIM_VERSION_FROM_PORTAL" ]]
then
    echo "INFO: Netsim Version $NETSIM_VERSION_INSTALLED is valid"
else
    echo "ERROR: Netsim Version $NETSIM_VERSION_INSTALLED is not valid. Kindly Please check"
    exit 207
fi
######################################################################
#Verification of NETSim Patches
######################################################################
SHELL_PATCH_FILE="/var/tmp/patchShellList.txt"

rm -rf $SHELL_PATCH_FILE
#########################################
su - netsim -c "echo '.show patch info' | /netsim/inst/netsim_shell | grep 'P[0-9]' > $SHELL_PATCH_FILE"

SHELL_PATCH_COUNT=`wc -l < $SHELL_PATCH_FILE`

PORTAL_PATCH_FILE=`ls $SIMDEP_CONTENTS | grep NetsimPatches_CXP9032769.Urls`

PORTAL_PATCH_COUNT=`cat  $SIMDEP_CONTENTS/$PORTAL_PATCH_FILE | wc -l`

if grep -q "No Patches Installed" $SHELL_PATCH_FILE
then
    if [ $PORTAL_PATCH_COUNT -eq 0 ] && [ $[SHELL_PATCH_COUNT - 2] -eq 0 ];
    then
        echo "INFO: No Patches are installed as 0 patches are present in CI Portal"
    else
        echo "ERROR: Few Patches are missing. Kindly please check"
        exit 207
    fi
else

    if [ $PORTAL_PATCH_COUNT -eq $[SHELL_PATCH_COUNT] ];
    then
        count=0
        while read patch; do
            IFS='/' read -ra ADDR <<< "$patch"
            if [[ ${ADDR[11]} == ${drop} ]]
            then 
                continue
            fi
            if grep -q "${ADDR[11]}" $SHELL_PATCH_FILE
            then
                echo "INFO: ${ADDR[11]} patch is successfully installed"
            else
                echo "ERROR: ${ADDR[11]} patch is missing. Kindly please install."
                count=$[count + 1]
            fi
        done <$SIMDEP_CONTENTS/$PORTAL_PATCH_FILE
        if [ $count -eq 0 ];
        then
            echo "INFO: All correct Patches are installed"
        else
            echo "ERROR: Few Patches are missing. Kindly please check"
            exit 207
        fi
    else
        echo "ERROR: Few Patches are missing. Kindly please check"
        exit 207
    fi
fi
########################################################
#Verification if all nodes are started
########################################################
SIMDEP_CONTENTS="/netsim/simdepContents"
NETWORK_TYPE=`ls $SIMDEP_CONTENTS | grep Simnet_.*.content | cut -d'_' -f 3`
if [ "$NETWORK_TYPE" != "8K" ]
then
    SIMS_NOT_STARTED=`su netsim -c 'echo ".show allsimnes" |/netsim/inst/netsim_shell | grep "not started"| cut -d" " -f1'`
    if [[ $SIMS_NOT_STARTED == "" ]] && [[ -z $SIMS_NOT_STARTED ]] ;
    then
        echo "INFO: All nodes are successfully started."
    else
        echo "ERROR: Few Nodes are not started. Kindly Please check"
        exit 207
    fi
else
    echo "[WARN]: Skipping Start Nodes Checking for 1.8K"
fi

########################################################
#Verification of Simulations
########################################################
SIM_SHELL_FILE="/var/tmp/simShellList.txt"
SIMULATION_URLS="/netsim/simdepContents/Simnet.Urls"
rm -rf $SIM_SHELL_FILE

su - netsim -c "echo '.show simulations' | /netsim/inst/netsim_shell | grep -v 'zip' > $SIM_SHELL_FILE"
SIM_SHELL_COUNT=`wc -l < $SIM_SHELL_FILE`

PORTAL_SIM_COUNT=`wc -l < $SIMULATION_URLS`

if [ $PORTAL_SIM_COUNT -eq 0 ] && [ $[SIM_SHELL_COUNT - 2] -eq 0 ];
then
    echo "INFO: No Sims are rolled out as 0 Sims are present in CI Portal"
elif [ $PORTAL_SIM_COUNT -eq $[SIM_SHELL_COUNT - 2] ];
then
    count=0
    while read Sims; do
        IFS='/' read -ra ADDR <<< "$Sims"
        if grep -q "${ADDR[11]}" $SIM_SHELL_FILE
        then
            echo "INFO: ${ADDR[11]} Sim is successfully rolled out"
        else
            echo "ERROR: ${ADDR[11]} Sim is missing. Kindly please rollout."
            count=$[count + 1]
        fi
    done <$SIMULATION_URLS
    if [ $count -eq 0 ];
    then
        echo "INFO: All correct Sims are properly rolled out"
    else
        echo "ERROR: Few Sims are missing. Kindly please check"
        exit 207
    fi
else
    echo "ERROR: Few Sims are missing. Kindly please check"
    exit 207
fi
##############################################################################################################
#verifying TLS/SL2 security on simulations
##############################################################################################################
if [[ "$securityTLS" == "on" ]]
then
echo "checking whether TLS certs are present on simulations"
sims=`ls /netsim/netsimdir | grep -E 'DG2|PICO|ESAPC|VSAPC|MSRBS|EPG|GSM-TCU|C608|ECM|RNNODE|vRM|vRSM|vPP|vRC|VTFRadioNode|5GRadioNode|VTIF|vSD|SpitFire.*17B|SpitFire.*18A|RNC.*PRBS|Router6274|Router6672|Router6675|Router6371|Router6471-1|Router6471-2|MSC|BSC|HLR' | grep -vE 'EPG-OI|zip'`
simsList=(${sims// / })
simsCount=${#simsList[@]}
if [[ $simsCount == 0 ]]
then
echo "NO TLS Simulations"
fi
for simName in ${simsList[@]}
do
if [[ $simName == *"CTC"* ]]
then
neName=`echo -e '.open '$simName' \n.show simnes' | su netsim -c /netsim/inst/netsim_shell | grep "LTE CTC" | cut -d ' ' -f1 | tail -1`
elif [[ $simName == *"BSC"* || $simName == *"MSC"* ]]
then
neName=`echo -e '.open '$simName' \n.show simnes' | su netsim -c /netsim/inst/netsim_shell | grep "LTE BSC" | cut -d ' ' -f1 | tail -1`
if [[ -z $neName ]]
then
neName=`echo -e '.open '$simName' \n.show simnes' | su netsim -c /netsim/inst/netsim_shell | grep "LTE MSC" | cut -d ' ' -f1 | tail -1`
fi
elif [[ $simName == *"vHLR"* ]]
then
neName=`echo -e '.open '$simName' \n.show simnes' | su netsim -c /netsim/inst/netsim_shell | grep "LTE vHLR" | cut -d ' ' -f1 | tail -1`
elif [[ $simName == *"HLR"* ]]
then
neName=`echo -e '.open '$simName' \n.show simnes' | su netsim -c /netsim/inst/netsim_shell | grep "LTE HLR" | cut -d ' ' -f1 | tail -1`
else
neName=`echo -e '.open '$simName' \n.show simnes' | su netsim -c /netsim/inst/netsim_shell | cut -d ' ' -f1 | grep -vE 'OK|NE|>>' | head -1`
fi
checkTLS=`echo -e '.open '$simName' \n.select '$neName' \n.show simne' | su netsim -c /netsim/inst/netsim_shell | grep "ssliop_def" | awk -F ':' '{print $2}' | sed 's/\"//g' | sed 's/ //g'`
if [[ (! -z $checkTLS ) && ( ! -z $neName ) ]]
then
echo "TLS was applied on $simName simulation"
elif [[ -z $neName ]]
then
echo "TLS support need nodes are not present $simName simulation"
else
echo "ERROR:TLS wasn't applied on $simName simulation"
exit 1
fi
done
fi

if [[ "$securitySL2" == "on" ]]
then
echo "checking whether SL2 certs are present on simulations"
sims=`ls /netsim/netsimdir/ | grep -ivE 'zip|DG2|NRF|NSSF|AUSF|UDR|PICO|RNNODE|vPP|vRM|vRSM|vRC|RAN-VNFM|EVNFM|VNF-LCM|VTFRadioNode|5GRadioNode|VTIF|vSD|HP-NFVO|RNC.*PRBS|RBS.*UPGIND'|grep -E 'LTE.*lim|MGW|MRS|-RBS|RNC.*UPGIND'`
simsList=(${sims// / })
simsCount=${#simsList[@]}
if [[ $simsCount == 0 ]]
then
echo "NO SL2 Simulations"
fi
for simName in ${simsList[@]}
do
neName=`echo -e '.open '$simName' \n.show simnes' |  su netsim -c /netsim/inst/netsim_shell | cut -d ' ' -f1 | grep -vE 'OK|NE|>>' | head -1`
checkSL2=`echo -e '.open '$simName' \n.select '$neName' \n.show simne' | su netsim -c /netsim/inst/netsim_shell | grep "ssliop_def" | awk -F ':' '{print $2}' | sed 's/\"//g' | sed 's/ //g'`
if [[ ! -z $checkSL2 ]]
then
echo "SL2 was applied on $simName simulation"
else
echo "ERROR:SL2 wasn't applied on $simName simulation"
exit 1
fi
done
fi
###############################################################
#Veirifying swapmemory
###############################################################
free > /netsim/simdepContents/output.txt

output=`cat /netsim/simdepContents/output.txt`

if [[ $output =~ "Swap:            0          0          0" ]]
then
    echo "ERROR: Swap Memory is not present in the server"
    echo "$output"
    exit 1
else
    echo "INFO: Swap Memory is present in the server"
    echo "$output"
fi

if [ -f /etc/centos-release ]
then
	echo "INFO: No need of swapMemory check for CentOS"
else
	currentSwap=`free -g | grep -w "Swap:" | awk '{print $2}'`
	Network=`ls /netsim/simdepContents | grep "Simnet_1_8K" | wc -l`
        check_2k=`cat /netsim/simdepContents/NRMDetails | grep "RolloutNetwork" | awk -F '=' '{print $2}'`
	if [ $Network -ne 1 ]
	then
                if [ $check_2k == "nssModule_RFA250_2K" ]
                then
                        echo "INFO : ${currentSwap}gb swap was present on the server"
                elif [ $currentSwap -lt 16 ]
		then
			echo "ERROR: 16GB of swapmemory is not present";
			exit 1
		else
		        echo "INFO:Relax!!!!! 16GB of swapmemory is present";
		fi
	fi
fi
################################################################
# Verification of Drop cache commmand in crontab
################################################################
if [[ ! -f /etc/centos-release ]]
then
check=`crontab -l | grep "/proc/sys/vm/drop_caches" | wc -l`
if [[ $check != 1 || $check > 1 ]]
then
echo -e "ERROR: Drop cache entry not updated properly in crontab"
exit 1
else
echo -e "INFO: Drop cache entry  updated properly in crontab"
fi
else
echo -e "INFO: Skipping Drop cache check for centos vms"
fi
#################################################################
# Verification of NRMDetails file
#################################################################
if [[ ! -f /netsim/simdepContents/NRMDetails ]]
then
   echo -e "ERROR: NRMDetails file was not present in simdepContents"
exit 1
else
   echo "INFO: NRMDDetails file was present in simdepContents"
fi
