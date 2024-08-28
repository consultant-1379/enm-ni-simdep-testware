#!/bin/bash

##############################################################################################
#     File Name     : updateTrustProfile.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : Imports CA certificates and updates trust profiles at ENM Side for vApps
#     Date Created  : 22 Mar 2017
##############################################################################################
##
##############################################
#Variable declarations
##############################################
dirSimNetDeployer="/var/tmp/Certs";
cliAppScriptPath='/opt/ericsson/enmutils/bin';
trustProfileIDLog="/var/tmp/trustProfileID.log"
trustProfileLog="/var/tmp/trustProfile.log"
externalCertsStatusLog="/var/tmp/externalCertsStatus.log"


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
msip="cloud-ms-1"
sh /var/tmp/executeCLI.sh $msip root 12shroot "$cliAppScriptPath/cli_app 'pkiadm extcalist'" > $externalCertsStatusLog
if [[ $? -ne 0 ]]
then
    echo "ERROR: Executing pkiadm extcalist command failed."
    exit 201
fi
chmod 777 $externalCertsStatusLog
cat $externalCertsStatusLog
extCAStatus=`cat $externalCertsStatusLog | grep ENM_ExtCA3 | grep NSSCA`

if [ -z "$extCAStatus" ] ; then
    echo "INFO: Certs are not present in ENM. Importing now.."

    ###################################################
    # Downloading certs from Nexus to ENM
    ###################################################
    cd /var/tmp/Certs
    echo "INFO: Copying s_cacert.pem from nexus"
   cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/s_cacert.pem .    
   if [[ $? -ne 0 ]]
    then
        echo "ERROR: Copying s_cacert.pem failed from simdep"
        exit 201
    fi
    echo "INFO:Copying trustProfile.xml"
    cp ${WORKSPACE}/ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/trustProfile.xml .
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Copying trustProfile.xml failed from simdep"
        exit 201
    fi

    ########################################################
    # Generating TrustProfile xml with existing profile data
    ########################################################
    sh /var/tmp/executeCLI.sh $msip root 12shroot "$cliAppScriptPath/cli_app 'pkiadm profilemgmt --export --profiletype trust --name ENM_SBI_FCTP_TP' --outfile=/var/tmp/Certs/existingProfileData.xml"
    sed 'x;$ e cat trustProfile.xml' /var/tmp/Certs/existingProfileData.xml | sed '$s/$/\n<\/Profiles>/;/^$/d' > trustProfileUpdate.xml

    #################################################
    # Running ENM Commands on cli_app
    #################################################
    sh /var/tmp/executeCLI.sh $msip root 12shroot "$cliAppScriptPath/cli_app 'pkiadm extcaimport -fn file:s_cacert.pem --chainrequired false --name \"ENM_ExtCA3\" ' $dirSimNetDeployer/s_cacert.pem" >> $trustProfileLog
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Importing s_cacert.pem failed"
        exit 201
    fi
    sh /var/tmp/executeCLI.sh $msip root 12shroot "$cliAppScriptPath/cli_app 'pkiadm pfm -u -xf file:trustProfileUpdate.xml' $dirSimNetDeployer/trustProfileUpdate.xml" >> $trustProfileLog
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
    sh /var/tmp/executeCLI.sh $msip root 12shroot "$cliAppScriptPath/cli_app 'pkiadm extcalist'"
    if [[ $? -ne 0 ]]
    then
        echo "ERROR: Executing pkiadm extcalist command failed."
        exit 201
    fi
else
    echo "INFO: Certs are already present in ENM. So, skipping certs configuration. "
    echo "INFO: Trust Profile is already sucessfully updated in ENM." >> $trustProfileLog
fi
