#!/bin/sh

#######################################################
#Created by  : zhainic
#Date        : May 27th,2020
#Arguments   : NSSDrop 
#Usage       : sh post_verification.sh 20.11
#######################################################

LogFile="/var/simnet/verification.log"

user=`whoami`
if [[ $user != "root" ]]
then
    echo "ERROR: Only Root user can excute this script" | tee -a $LogFile
    exit 1
fi

if [[ $# -ne 1 ]]
then
    echo "ERROR: Invalid argument" | tee -a $LogFile
    echo "Usage: ./post_verification.sh NSSDrop" | tee -a $LogFile
    exit 1
fi

if [[ ! -f $LogFile ]]
then
   touch $LogFile;chmod 777 $LogFile
fi

NSSDrop=$1

if [[ -z "$(ls -A /var/simnet/SW_verification/${NSSDrop})" ]]
then
    echo "INFO: Pre information files are not present in /var/simnet/SW_verification/${NSSDrop}/" | tee -a $LogFile
    exit 0
fi

echo "INFO: Verifing the Port,DD and DDIP after netsim update" | tee -a $LogFile

echo "INFO: Running /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/postPort_verification.sh ${NSSDrop}" | tee -a $LogFile

su netsim -c 'sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/postPort_verification.sh '${NSSDrop}'' | tee -a $LogFile
if [[ $? -ne 0 ]]
then
    echo "ERROR: Unable to verify the port,DD and DDIP data post netsim update" | tee -a $LogFile
    exit 1
fi

echo "INFO: Running /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/postPM_verification.sh ${NSSDrop}" | tee -a $LogFile
su netsim -c 'sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/postPM_verification.sh '${NSSDrop}'' | tee -a $LogFile
if [[ $? -ne 0 ]]
then
   echo "ERROR: Unable to verify PM data post netsim update" | tee -a $LogFile
   exit 1
fi
mv /var/simnet/verification.log /var/simnet/SW_verification/${NSSDrop}/