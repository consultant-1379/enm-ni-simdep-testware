#!/bin/sh

#######################################################
#Created by  : zhainic
#Date        : May 27th,2020
#Arguments   : NSS Drop
#Usage       : sh pre_verification.sh
#######################################################

LogFile="/var/simnet/verification.log"
if [[ -f $LogFile ]]
then
    rm -rf $LogFile
fi
touch $LogFile;chmod 777 $LogFile

Info_collector()
{
    Drop=$1
    chmod 777 /var/simnet/SW_verification/${NSSDrop}/
    echo "INFO: Collecting the info need for post netsim update verification" | tee -a $LogFile
    echo "INFO: Files are being stored under /var/simnet/SW_verification/${NSSDrop}/ " | tee -a $LogFile
    echo "INFO: Running /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/preInfo_collector.sh $Drop" | tee -a $LogFile

    su netsim -c 'sh /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/preInfo_collector.sh '${Drop}'' | tee -a $LogFile

    if [[ $? -ne 0 ]]
    then
        echo "Unable to collect the information need for post netsim update verification" | tee -a $LogFile
        exit 1
    fi
    echo "INFO: Collected the all data needed for post verification" | tee -a $LogFile
}

user=`whoami`
if [[ $user != "root" ]]
then
    echo "ERROR: Only Root user can excute this script" | tee -a $LogFile
    exit 1
fi

if [[ $# -ne 1 ]]
then
    echo "ERROR: Invalid argument" | tee -a $LogFile
    echo "Usage: ./pre_verification.sh NSSDrop" | tee -a $LogFile
    exit 1
fi

NSSDrop=$1

if [[ ! -d /var/simnet/SW_verification/ ]]
then 
    mkdir /var/simnet/SW_verification
    if [[ $? -ne 0 ]]
    then
            echo "failed to creat the directory /var/simnet/SW_verification/"
            exit 206
    fi

    mkdir /var/simnet/SW_verification/${NSSDrop}
    if [[ $? -ne 0 ]]
    then
            echo "failed to creat the directory /var/simnet/SW_verification/${NSSDrop}"
            exit 206
    fi
    #function call to collect the data
    Info_collector $NSSDrop
else
    if [[ ! -d /var/simnet/SW_verification/${NSSDrop} ]]
    then
        rm -rf /var/simnet/SW_verification/*

        mkdir /var/simnet/SW_verification/${NSSDrop}
        if [[ $? -ne 0 ]]
        then
                echo "failed to creat the directory /var/simnet/SW_verification/${NSSDrop}"
                exit 206
        fi
        #function call to collect the data################
        Info_collector $NSSDrop
     else
        if [[ -z "$(ls -A /var/simnet/SW_verification/${NSSDrop})" ]]
        then
            echo "INFO: Pre information files are not present in /var/simnet/SW_verification/${NSSDrop}/" | tee -a $LogFile
            Info_collector $NSSDrop
        else
            echo "INFO: Pre information files are present under the path /var/simnet/SW_verification/${NSSDrop}/" | tee -a $LogFile
        fi
    fi
fi
