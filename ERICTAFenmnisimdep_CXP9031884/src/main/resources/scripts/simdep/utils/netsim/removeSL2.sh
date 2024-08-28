#!/bin/bash
#
##################################################################
#     File Name : removeSL2.sh
#     Author: Sneha Srivatsav Arra, Fatih ONUR
#     Description : Removes SL2 Security Definition for CPP:ERBS|MGw|RNC|RBS Nodes.
#     Date Created : 04 May 2016
#
#####################################################################
#
#####################################################################
# Env variables
#####################################################################
NETSIM_DIR=/netsim/netsimdir
NETSIM_INST=/netsim/inst
#####################################################################
# MAIN
#####################################################################
LOGFILE=/tmp/removeSL2.log
PWD=`pwd`
NOW=`date +"%Y_%m_%d_%T:%N"`
MMLSCRIPT=clean.mml

if [ -f $PWD/$MMLSCRIPT ]
then
    rm -r  $PWD/$MMLSCRIPT
    echo "old "$PWD/$MMLSCRIPT" removed"
fi

if [ -f $LOGFILE ]
then
    rm -r  $LOGFILE
    echo "old "$LOGFILE" removed"
fi

echo "... $0 script started running at "`date` | tee -a $LOGFILE
echo "" | tee -a $LOGFILE


###########################################################################
# Make MML Script
###########################################################################

echo "<`date '+%X'`>-INFO: SL2: Making MML script if CPP:ERBS|MGw|RNC|RBS nodes exist" | tee -a $LOGFILE
#
#############################################################################
#Remove Security Definition
#############################################################################
SIM_FILE=/tmp/sims_list_cpp.txt
cd $NETSIM_DIR
ls | egrep -i 'LTE|MGW|RNC' | egrep -vi 'DG2|mml|PICO|MSRBS|TLS|EVNFM|VNFM|VNF|RNNODE|VPP|VRC|VTFRadioNode|5GRadioNode' | grep -v zip > $SIM_FILE

while read sim; do
echo "<`date '+%X'`>-INFO: SL2: Removing Security Definition for $sim" | tee -a $LOGFILE
cd $NETSIM_INST
echo ".open $sim" >> $MMLSCRIPT
echo ".select network" >> $MMLSCRIPT
echo ".stop -parallel" >> $MMLSCRIPT
echo ".setssliop delete /netsim/netsimdir/$sim SL2" >> $MMLSCRIPT
done < $SIM_FILE

if [[ -f $MMLSCRIPT ]]; then
    echo "<`date '+%X'`>-INFO: SL2: Running MML script " | tee -a $LOGFILE
    (/netsim/inst/netsim_pipe < $MMLSCRIPT) |  tee -a $LOGFILE
    rm $PWD/$MMLSCRIPT
else
    echo "<`date '+%X'`>-INFO: SL2: There is no CPP:ERBS|MGW|RNC|RBS nodes " | tee -a $LOGFILE
fi

echo " *****************************************************" | tee -a $LOGFILE
echo " *    Security Definition is removed for CPP:ERBS|MGW|RNC|RBS nodes   *" | tee -a $LOGFILE
echo " *****************************************************" | tee -a $LOGFILE
echo ""

echo "...$0 script ended at "`date` | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

exit 0

#
##############################################################################
# End of the script
##############################################################################
