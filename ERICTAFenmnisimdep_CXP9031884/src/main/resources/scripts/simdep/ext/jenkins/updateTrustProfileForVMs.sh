#!/bin/bash

############################################################################################
#     File Name     : updateTrustProfileForVMs.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : Imports CA certificates and updates trust profiles at ENM Side for VMs
#     Date Created  : 22 Mar 2017
#############################################################################################
##
##############################################
#Variable declarations
##############################################
dirSimNetDeployer="/var/tmp/Certs";
cliAppScriptPath='/opt/ericsson/enmutils/bin';
trustProfileIDLog="/var/tmp/trustProfileID.log"
trustProfileLog="/var/tmp/trustProfile.log"
externalCertsStatusLog="/var/tmp/externalCertsStatus.log"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENM_URL=$1

echo "INFO: Removing $dirSimNetDeployer"
rm -rf $dirSimNetDeployer
if [[ $? -ne 0 ]]
then
    echo "ERROR: Removing $dirSimNetDeployer failed"
    exit 201
fi
echo "INFO: Making $dirSimNetDeployer"
mkdir $dirSimNetDeployer
if [[ $? -ne 0 ]]
then
    echo "ERROR: Making $dirSimNetDeployer failed"
    exit 201
fi
#################################################
# Removing trustProfile Logs
#################################################
rm -rf $trustProfileIDLog
rm -rf $trustProfileLog
rm -rf $externalCertsStatusLog

#################################################
# Status of external CA before importing
#################################################
echo "INFO: Status of external CAs before importing"
/var/tmp/runCliCommand.py 'pkiadm extcalist' $ENM_URL > $externalCertsStatusLog
if [[ $? -ne 0 ]]
then
    echo "ERROR: Executing pkiadm extcalist command failed."
    exit 201
fi
chmod 777 $externalCertsStatusLog
cat $externalCertsStatusLog
serialStatus=`cat $externalCertsStatusLog | grep ecd40f29a35fdcb5`
if [[ ! -z $serialStatus ]]; then
    echo "INFO: Nss old certs are present removing old nss certs from ENM"
    
    /var/tmp/runCliCommand.py 'pkiadm profilemgmt --export --profiletype trust --name ENM_SBI_FCTP_TP' $ENM_URL downloadFile /var/tmp/Certs/existingProfileData_remove.xml
    
    /var/tmp/modifyXml.py /var/tmp/Certs/existingProfileData_remove.xml /var/tmp/Certs/existingProfileData_after_remove.xml

    xmlDeclaration=`cat /var/tmp/Certs/existingProfileData_remove.xml | head -1`  
    
    sed -i '1i\'"$xmlDeclaration" /var/tmp/Certs/existingProfileData_after_remove.xml

    /var/tmp/runCliCommand.py 'pkiadm pfm -u -xf file:existingProfileData_after_remove.xml' $ENM_URL /var/tmp/Certs/existingProfileData_after_remove.xml >> $trustProfileLog
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Updating Trust Profile failed"
        exit 201
    fi
    chmod 777 $trustProfileLog
    /var/tmp/runCliCommand.py 'pkiadm extcaremove --name ENM_ExtCA3' $ENM_URL  > $externalCertsStatusLog
    if [[ $? -ne 0 ]]
    then
       echo "ERROR: Executing pkiadm extcalist command failed."
       exit 201
    fi
    chmod 777 $externalCertsStatusLog
    cat $externalCertsStatusLog
fi

extCAStatus=`cat $externalCertsStatusLog | grep ENM_ExtCA3 | grep NSSCA`

trustStatus=`cat $externalCertsStatusLog | grep ENM_ExtCA3 | grep NSSCA | grep ENM_SBI_FCTP_TP`

if [[ -z "$trustStatus" ]]; then
	extCAStatus=`cat $externalCertsStatusLog | grep ENM_ExtCA3 | grep NSSCA`
    cd /var/tmp/Certs
	if [[ -z "$extCAStatus" ]]; then
		echo "INFO: Certs are not present in ENM. Importing now.."
        ###################################################
        # Downloading certs from Nexus to ENM
        ###################################################
        #echo "INFO: Downloading s_cacert.pem from nexus"
        cp ${SCRIPT_DIR}/s_cacert.pem .
        if [[ $? -ne 0 ]]
        then
            echo "ERROR: Copying s_cacert.pem failed from simdep"
            exit 201
        fi
		#################################################
        # Running ENM Commands on cli_app
        #################################################
        /var/tmp/runCliCommand.py 'pkiadm extcaimport -fn file:s_cacert.pem --chainrequired false --name "ENM_ExtCA3"' $ENM_URL $dirSimNetDeployer/s_cacert.pem >> $trustProfileLog
        if [[ $? -ne 0 ]]
        then
            echo "ERROR: Importing s_cacert.pem failed"
            exit 201
        fi
	else
		echo "INFO: Certs are present in ENM but not added to TrustProfile. Adding to trustProfile now.."
	fi
	
	#echo "INFO: Downloading trustProfile.xml"
   cp  ${SCRIPT_DIR}/trustProfile.xml .
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Copying trustProfile.xml failed from simdep"
        exit 201
    fi
    
    #################################################
    # Replacing TrustProfile ID of ENM_SBI_FCTP_TP
    #################################################
    /var/tmp/runCliCommand.py 'pkiadm profilemgmt --export --profiletype trust --name ENM_SBI_FCTP_TP' $ENM_URL downloadFile /var/tmp/Certs/existingProfileData.xml
    sed 'x;$ e cat trustProfile.xml' /var/tmp/Certs/existingProfileData.xml | sed '$s/$/\n<\/Profiles>/;/^$/d' > trustProfileUpdate.xml
    

    /var/tmp/runCliCommand.py 'pkiadm pfm -u -xf file:trustProfileUpdate.xml' $ENM_URL $dirSimNetDeployer/trustProfileUpdate.xml >> $trustProfileLog
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Updating Trust Profile failed"
        exit 201
    fi
    chmod 777 $trustProfileLog
    cat $trustProfileLog
    
    #################################################
    # Status of external CA after importing
    #################################################
    echo "INFO: After updating trust profile"
    /var/tmp/runCliCommand.py 'pkiadm extcalist' $ENM_URL
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Executing pkiadm extcalist command failed."
        exit 201
    fi
else
	echo "INFO: Certs are already present in ENM. So, skipping certs configuration. "
	echo "INFO: Trust Profile is already sucessfully updated in ENM." >> $trustProfileLog
fi 
