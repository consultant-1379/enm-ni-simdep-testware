#!/bin/bash
#
##################################################################
#     File Name : removeTLS.sh
#     Author: Sneha Srivatsav Arra, Fatih ONUR
#     Description : Removes TLS Security Definition for DG2|LTE PICO|CORE-vSAPC|CORE-EPG|CORE-vEPG|CORE-TCU|WRAN PICO nodes
#     Date Created : 04 May 2016
#
#####################################################################
#
#####################################################################
# Env variables
#####################################################################
NETSIM_DIR=/netsim/netsimdir
NETSIM_INST=/netsim/inst
TLS_SIMS="DG2|LTE PICO|CORE-vSAPC|CORE EPG-SSR|CORE EPG-EVR|GSM-TCU03|WRAN PICO|GSM-TCU04|CORE-C608|CORE ECM|LTE TLS-RNNODE|LTE TLS-VPP|LTE TLS-VRC|LTE EVNFM|LTE VNFM|LTE VNF"
#####################################################################
# MAIN
#####################################################################
LOGFILE=/tmp/removeTLS.log
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

echo "<`date '+%X'`>-INFO: TLS: Making MML script if $TLS_SIMS nodes exist" | tee -a $LOGFILE
#
#############################################################################
#Remove Security Definition
#############################################################################
SIM_FILE=/tmp/sims_list_dg2.txt
cd $NETSIM_DIR
ls | egrep "DG2|PICO|MSRBS|ESAPC|EPG|TCU03|TCU04|C608|ECM|TLS|RAN-VNFM|EVNFM|VNF-LCM" | grep -v zip > $SIM_FILE

while read sim; do
echo "<`date '+%X'`>-INFO: TLS: Removing Security Definition for $sim" | tee -a $LOGFILE
cd $NETSIM_INST
echo ".open $sim" >> $MMLSCRIPT
echo ".select network" >> $MMLSCRIPT
echo ".stop -parallel" >> $MMLSCRIPT
echo ".restorenedatabase curr all force" >> $MMLSCRIPT
echo ".setssliop delete /netsim/netsimdir/$sim TLS" >> $MMLSCRIPT
done < $SIM_FILE

if [[ -f $MMLSCRIPT ]]; then
    echo "<`date '+%X'`>-INFO: TLS: Running MML script " | tee -a $LOGFILE
    (/netsim/inst/netsim_pipe < $MMLSCRIPT) |  tee -a $LOGFILE
    rm $PWD/$MMLSCRIPT
else
    echo "<`date '+%X'`>-INFO: TLS: There is no $TLS_SIMS nodes " | tee -a $LOGFILE
fi

echo " *****************************************************" | tee -a $LOGFILE
echo " *    Security Definition is removed for $TLS_SIMS nodes  *" | tee -a $LOGFILE
echo " *****************************************************" | tee -a $LOGFILE
echo ""

echo "...$0 script ended at "`date` | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

exit 0

#
##############################################################################
# End of the script
##############################################################################
