#! /bin/bash

# Created by  : Komal Chowdhary
# Created on  : 27.11.2014

### VERSION HISTORY
# Version     : 1.0
# Purpose     : Utility to Clean the Vapp 
# Date        : 27 NOV 2014
# Who         : Komal Chowdhary
#Description  : The script runCleanVapp cleans simulations both from netsim and oss server.


################################
# Env variables
################################
VAPP_LOGFILE=/tmp/cleanVapp.log
NUMARGS=$#

#Delete existing log files
if [ -f $VAPP_LOGFILE ]
then
    rm -r  $VAPP_LOGFILE
    echo "INFO: Old $VAPP_LOGFILE removed"
fi


#Check the number of arguments. If none are passed, print help options and exit###########
if [ $NUMARGS -eq 0 ];
then
    echo "./runCleanVapp.sh: invalid option "
    echo "Try './runCleanVapp.sh -h' for more information"
    exit
fi

### Start getopts code ###
while getopts novh name
do
    case $name in
      n)nopt=1;;
      o)oopt=1;;
      v)vopt=1;;
      h)echo "--USAGE OF THE SCRIPT--"
	###option to run the clean oss server##########
        echo "To clean the Oss "
        echo "./runCleanVapp.sh -o "
	echo ""
	###option to run the clean Netsim server##########
        echo "To clean the Netsim Server "
        echo "./runCleanVapp.sh -n "
	echo ""
	###option to run the clean Vapp##########
        echo "To clean the Vapp "
        echo "./runCleanVapp.sh -v "
	echo ""
        echo "To kill the script press ctrl+c twice"
	echo ""
	exit
        ;;
     ###Invalid options passed##########
     *)echo "Invalid arg";;
    esac
done

###################################
#catch control-c keyboard interrupts
###################################

control_c()
{
   echo -en "\n*** Ouch! Exiting ***\n" | tee -a $VAPP_LOGFILE
    /bin/ps -eaf | grep $0 | grep -v grep | awk '{print $2}' | xargs kill -9 | tee -a $VAPP_LOGFILE
   exit $?
}

################################################
# Main Loop
################################################
echo "... $0 script started running at "`date` | tee -a $VAPP_LOGFILE
echo "" | tee -a $VAPP_LOGFILE

# trap keyboard interrupt (control-c)
trap control_c SIGINT

if [[ ! -z $nopt ]]
then
    echo "INFO:Run clean netsim" | tee -a $VAPP_LOGFILE
    ./cNetsim.sh | tee -a $VAPP_LOGFILE
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        echo "ERROR: Netsim Clean failed!!!" | tee -a $VAPP_LOGFILE
        exit -1
    fi
    echo "INFO:Netsim server is cleaned now" | tee -a $VAPP_LOGFILE
fi
######################################################
if [[ ! -z $oopt ]]
then
    echo "INFO:Run clean oss" | tee -a $VAPP_LOGFILE
    ./expect_env.sh | tee -a $VAPP_LOGFILE
    echo "INFO:Oss server is cleaned now" | tee -a $VAPP_LOGFILE
fi

###################################################
if [[ ! -z $vopt ]]
then
    echo "INFO:Run clean Vapp" | tee -a $VAPP_LOGFILE
    #Invoking expect environment expect_env.exp from bash script
    ./expect_env.sh | tee -a $VAPP_LOGFILE

    ./cNetsim.sh | tee -a $VAPP_LOGFILE
    echo " ***************************************" | tee -a $VAPP_LOGFILE
    echo " *    Vapp is cleaned    *" | tee -a $VAPP_LOGFILE
    echo " ***************************************" | tee -a $VAPP_LOGFILE
fi

exit 

