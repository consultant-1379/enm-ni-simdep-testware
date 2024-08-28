#!/bin/sh

# Created by  : Komal Chowdhary
# Created on  : 27.11.2014

### VERSION HISTORY
# Version     : 2.0
# Purpose     : Utility to Clean the Netsim and reset load balancing.
# Description : Development and testing of simulations
# Date        : 2016 SEP 09
# Who         : Fatih ONUR

trap onError INT TERM EXIT
set -o nounset  # will exit the script if an uninitialised variable is used.
set -o pipefail # will take the error status of any item in a pipeline.

################################
# ENV VARIABLES
################################
LOGFILE=/tmp/cleanNetsim.log
PWD=`pwd`
NOW=`date +"%Y_%m_%d_%T:%N"`
MMLSCRIPT=/tmp/clean.mml


################################
# FUNCTIONS
################################
function catchError {
    if [[ $? -ne 0 ]]
    then
        echo "$1" | tee -a $LOGFILE
        exit -1
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

function safelyReStartNetsim {
    EXIT_CODE=0
    for i in 1 2 3
    do
        SLEEP=15
        if [ $i -eq 1 ] ; then SLEEP=0; fi
        echo "<`date '+%X'`>-INFO: NETSim restart attempt ($i/3). SleepingTime=${SLEEP}seconds" | tee -a $LOGFILE
        sleep $SLEEP
        /netsim/inst/restart_netsim fast |  tee -a $LOGFILE
        EXIT_CODE=$?
        if [ $EXIT_CODE == 0 ]; then break; fi
    done
    if [ $EXIT_CODE != 0 ]; then
        echo "<`date '+%X'`>-ERROR: Restarting netsim failed!!!" | tee -a $LOGFILE
        exit -1;
    fi
}


################################
# MAIN
################################
CMD_TO_DELETE_TMP_FOLDER="rm -rf /tmp/* 2> /dev/null"
./expect_root.sh "$CMD_TO_DELETE_TMP_FOLDER" | tee -a $LOGFILE
echo "<`date '+%X'`>-INFO: Deleted /tmp folder contents" | tee -a $LOGFILE

echo "... $0 script started running at "`date` | tee -a $LOGFILE
echo "" | tee -a $LOGFILE


#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""
##########################################
#Deleting Ports and Default Destination
###########################################
echo .select configuration >> $MMLSCRIPT

# .config empty command deletes both port and default destination
echo .config empty >> $MMLSCRIPT

echo .config save >> $MMLSCRIPT

##############################################
#Deleting all network Simulations
###############################################
NETSIMDIR=/netsim/netsimdir
SIMULATIONS=`ls -l $NETSIMDIR/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" | perl -ne 'print if/! ^default$/'`

#############restart netsim gui incase it is used by some UI####################
echo "<`date '+%X'`>-INFO: Restarting netsim to stop gui and nodes fastly" | tee -a $LOGFILE
echo ""
safelyReStartNetsim

echo "<`date '+%X'`>-INFO: Deleting existing simulation zip files" | tee -a $LOGFILE
echo ""
rm -vrf /netsim/netsimdir/*.zip | tee -a $LOGFILE

NETSIM_USER_INST=`ls /netsim/ | grep netsimuserinstallation`
if [ ! -z "$NETSIM_USER_INST" ]; then
    echo "<`date '+%X'`>-INFO: Removing /netsim/$NETSIM_USER_INST/* directory as part of clean up" | tee -a $LOGFILE
    echo ""
    rm -rf /netsim/$NETSIM_USER_INST/* | tee -a $LOGFILE
fi

echo "<`date '+%X'`>-INFO: Deleting Netsim Ports and Default Destination" | tee -a $LOGFILE
echo ""
echo "<`date '+%X'`>-INFO: Deleting existing simulations" | tee -a $LOGFILE
echo ""
echo "$SIMULATIONS" | while read sim
do
    echo ".deletesimulation $sim force" >> $MMLSCRIPT
done

echo "stopping netsim"
/netsim/inst/stop_netsim fast

echo "<`date '+%X'`>-INFO: Deleting contents of $NETSIMDIR" | tee -a $LOGFILE
CMD_TO_DELETE_CONTENTS_OF_NETSIMDIR="rm -rf $NETSIMDIR/*"
./expect_root.sh "$CMD_TO_DELETE_CONTENTS_OF_NETSIMDIR"

echo ""
safelyReStartNetsim

###############################################
#Resetting load balance
###############################################
echo "<`date '+%X'`>-INFO: Resetting load balance" | tee -a $LOGFILE
echo ".reset serverloadconfig" >> $MMLSCRIPT
echo "<`date '+%X'`>-INFO: Showing the latest load balancing configuration" | tee -a $LOGFILE
echo ".show serverloadconfig" >> $MMLSCRIPT

(/netsim/inst/netsim_shell -stop_on_error < $MMLSCRIPT) |  tee -a $LOGFILE
catchError "<`date '+%X'`>-ERROR: Failed to reset load balancing!!!"

###############################################
#Deleting security folder TLS and SLS
################################################
CMD_TO_DELETE_SECURITY_FOLDERS="rm -rf /netsim/netsimdir/Security"
echo "<`date '+%X'`>-INFO: Deleting security folder TLS and SLS" | tee -a $LOGFILE
./expect_root.sh "$CMD_TO_DELETE_SECURITY_FOLDERS" | tee -a $LOGFILE
echo ""

###############################################
#Cleaning tmpfs folder
###############################################
TMPFS_DIR=/pms_tmpfs
CMD_TO_CLEAN_TMPFS_DIR="rm -rf $TMPFS_DIR/*"
echo "<`date '+%X'`>-INFO: Cleaning $TMPFS_DIR folder" | tee -a $LOGFILE
echo ""
./expect_root.sh "$CMD_TO_CLEAN_TMPFS_DIR" | tee -a $LOGFILE

###############################################
#Cleaning netsim db
################################################
NETSIM_DB_DIR=/netsim/netsim_dbdir/simdir/netsim/netsimdir
CMD_TO_CLEAN_NETSIM_DB_DIR="rm -rf $NETSIM_DB_DIR/*"
echo "<`date '+%X'`>-INFO: Cleaning $NETSIM_DB_DIR" | tee -a $LOGFILE
echo
./expect_root.sh "$CMD_TO_CLEAN_NETSIM_DB_DIR"  | tee -a $LOGFILE
for SIM in $(cd $NETSIM_DB_DIR && ls -d *)
do
    SIM=$(echo $SIM | sed 's%/%%')

    echo "INFO: Unmounting $SIM" | tee -a $LOGFILE
    /usr/bin/expect  <<EOF | tee -a $LOGFILE
    spawn su root -c "umount /netsim/netsim_dbdir/simdir/netsim/netsimdir/$SIM/*/fs/c/pm_data"
    expect {
        -re assword: {send "shroot\r";exp_continue}
    }
EOF
done
./expect_root.sh "$CMD_TO_CLEAN_NETSIM_DB_DIR"  | tee -a $LOGFILE

###############################################
#Cleaning olde netsim versions
################################################
echo "<`date '+%X'`>-INFO: Cleaning older than 60 days NETSim software under /var/netsim" | tee -a $LOGFILE
for file in `find /var/netsim/* -maxdepth 0 -type d -mtime +60`
do
    ./expect_root.sh "rm -rf $file" | tee -a $LOGFILE
done

###############################################
#Restarting The Netsim
###############################################
echo "<`date '+%X'`>-INFO: Restarting netsim for changes to be saved" | tee -a $LOGFILE
echo ""
safelyReStartNetsim

echo "<`date '+%X'`>-INFO: Starting netsim gui for immediate usage" | tee -a $LOGFILE
echo ""
/netsim/inst/restart_gui |  tee -a $LOGFILE



#########################
# End of the script
#######################
rm -rf $PWD/$MMLSCRIPT

echo "...$0 script ended at "`date` | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

echo " ***************************************" | tee -a $LOGFILE
echo " *    Netsim is cleaned    *" | tee -a $LOGFILE
echo " ***************************************" | tee -a $LOGFILE

exit 0
