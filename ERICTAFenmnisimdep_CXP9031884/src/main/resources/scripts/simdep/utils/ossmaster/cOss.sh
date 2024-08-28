#!/bin/sh
# Created by  : Komal Chowdhary
# Created on  : 27.11.2014

### VERSION HISTORY
# Version     : 2.0
# Purpose     : Utility to Clean the Oss 
# Description : Development and testing of simulations 
# Date        : 27 NOV 2014
# Who         : Komal Chowdhary

################################
# Env variables
################################
HOST=`hostname`
HOSTVALUE='ossmaster'
USER=`/usr/ucb/whoami`
USERVALUE='root'

#########################################
# Check that the user runs the utility on ossmaster 
#########################################
 
if [ $HOST != $HOSTVALUE ]; 
then
     echo "Please run the cleanOss script on ossmaster"
     exit 1
fi

#########################################
# Check that the user is root 
#########################################

if [ $USER != $USERVALUE ]; 
then
     echo "Please run the cleanOss Script as a root user"
     exit 1
fi

#########################################
#MAIN
#########################################

#########################################
#Step by step procedure to clean the vapp
#########################################

echo "`date`  INFO: Cleaning of Oss started\n" | tee -a /tmp/cleanOss.log
echo "<`date '+%X'`>-INFO:---PLEASE WAIT UNTIL SCRIPT IS FINISHED SUCCESFULLY----\n" | tee -a /tmp/cleanOss.log
/opt/ericsson/fwSysConf/bin/removeDb.sh | tee -a /tmp/cleanOss.log
/opt/ericsson/fwSysConf/bin/createDb.sh | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Colderestart of ARNE and MAF server\n" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool coldrestart ONRM_CS ARNEServer MAF NodeSynchServer -reason="planned" -reasontext="planned" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool -p | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Offline Seg_CS and Region_CS\n" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool offline Seg_masterservice_CS Region_CS -reason="planned" -reasontext="planned" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool -p | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Switching to nmsadm user now to start the database...\n" | tee -a /tmp/cleanOss.log
su - nmsadm  -c "/opt/ericsson/nms_umts_wranmom/bin/start_databases.sh -f" | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Databases are now started! \n" | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Switching back to Root user...\n" | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Online Seg_CS and Region_CS\n" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool online Seg_masterservice_CS Region_CS | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool -p | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Coldrestart All the MC's....\n" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool coldrestart -all -reason="planned" -reasontext="planned" | tee -a /tmp/cleanOss.log
/opt/ericsson/bin/smtool -p | tee -a /tmp/cleanOss.log


echo "<`date '+%X'`>-INFO: Now you should import all ftp services on oss\n" | tee -a /tmp/cleanOss.log
 
echo "<`date '+%X'`>-INFO: ---PLEASE WAIT UNTIL SCRIPT IS FINISHED SUCCESFULLY----\n"  | tee -a /tmp/cleanOss.log
###################################################
#Cold restart of all MC's will take 25minutes 
#####################################################

echo "<`date '+%X'`>-INFO: Background cold restart is running which takes 25mins to complete\n" | tee -a /tmp/cleanOss.log
echo "<`date '+%X'`>-INFO: Sleep for 25minutes....\n" | tee -a /tmp/cleanOss.log
sleep 1500

echo "<`date '+%X'`>-INFO: Deleting *upgraded_temp.xml files\n" | tee -a /tmp/cleanOss.log
/usr/bin/rm -rf /var/opt/ericsson/arne/FTPServices/*upgraded_temp.xml | tee -a /tmp/cleanOss.log

##################################################
# Import all ftp services on oss
###################################################
echo "<`date '+%X'`>-INFO: FTP services import process is starting\n" | tee -a /tmp/cleanOss.log
ls /var/opt/ericsson/arne/FTPServices/* | egrep -v "(temp|DEL|MOD)" |  while read line
do
   echo "<`date '+%X'`>-INFO:Now importing $line"
   /opt/ericsson/arne/bin/import.sh -f $line  -import -i_nau | tee -a /tmp/cleanOss.log
done

###########################################################################
#Delete previous logs from below mentioned directories on oss master 
#( In order to Pass full integration test and also space issue will be taken care)
###########################################################################
 
echo "<`date '+%X'`>-INFO: Cleaning logs from /tmp folder \n" | tee -a /tmp/cleanOss.log
/usr/bin/rm -rf /tmp/* | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Cleaning logs from /ossrc/upgrade/JREheapdumps/ folder \n" | tee -a /tmp/cleanOss.log
/usr/bin/rm -rf /ossrc/upgrade/JREheapdumps/* | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Cleaning logs from /ossrc/upgrade/core/ folder \n" | tee -a /tmp/cleanOss.log
/usr/bin/rm -rf /ossrc/upgrade/core/* | tee -a /tmp/cleanOss.log

echo "<`date '+%X'`>-INFO: Cleaning logs from cloud_network_xmls/ folder \n" | tee -a /tmp/cleanOss.log
/usr/bin/rm -rf /cloud_network_xmls/* | tee -a /tmp/cleanOss.log
 
###############################################################################
#This completes cleaning of ossmaster
#############################################################################

echo ""| tee -a /tmp/cleanOss.log
echo " ***************************************" | tee -a /tmp/cleanOss.log
echo " *    OSS is now cleaned    *" | tee -a /tmp/cleanOss.log
echo " ***************************************" | tee -a /tmp/cleanOss.log
echo ""| tee -a /tmp/cleanOss.log
echo "$0: ended at `date`" | tee -a /tmp/cleanOss.log

