#!/bin/bash
#
##############################################################################
#     File Name     : genstats_prechecks.sh
#     Author        : Harsha Yeluru
#     Description   : This script is responsible for pre-health checks of Genstats
#                     including all nodes in sims are in STARTED state or not and
#                     SCANNER state of all sims
#     Date Created  : 12 July 2017
###############################################################################
#
########################################################
#Constants Declaration
########################################################
INSTALL_DIR=`dirname $0`
INSTALL_PATH=`cd ${INSTALL_DIR} ; pwd`
TEMP=/tmp
PMDIR=/pms_tmpfs
LOG_FILE="/$INSTALL_PATH/preHealthCheckGenstats.log"
########################################################
#Variables Declaration
########################################################
failureFlag=false
failureFlag_scan=false
failureFlag_node=false
failureFlag_dir=false
########################################################
#This method is used to log input messages
########################################################
log(){
    msg=$1
        timestamp=`date +%H:%M:%S`
        MSG="${timestamp} ${msg}"

    echo $MSG >> $LOG_FILE
        echo $MSG
}
########################################################
#Main
########################################################
if [ ! -d $TEMP ];then
   mkdir -p $TEMP
fi

if [ ! -d $PMDIR ];then
    log "ERROR: $PMDIR does not exist."
    exit 1
fi

if [ ! -d $NETSIMDIR ];then
    log "ERROR: $NETSIMDIR does not exist."
    exit 1
fi

########################################################
#Verification if all nodes are started
########################################################
log "INFO: Start Processing"
log "INFO: Checking if any node is stopped"
SIMDEP_CONTENTS="/netsim/simdepContents"
NETWORK_TYPE=`ls $SIMDEP_CONTENTS | grep Simnet_.*.content | cut -d'_' -f 3`
if [ "$NETWORK_TYPE" != "8K" ]
then
    SIMS_NOT_STARTED=`su netsim -c 'echo ".show allsimnes" |/netsim/inst/netsim_shell | grep "not started"| cut -d" " -f1'`
    if [[ $SIMS_NOT_STARTED == "" ]] && [[ -z $SIMS_NOT_STARTED ]] ;
    then
        log "INFO: All nodes are successfully started."
    else
        failureFlag=true
        failureFlag_node=true
    fi
    if [ $failureFlag_node = true ];then
        log "ERROR: Few nodes are not started. Kindly Please Check"
    fi
else
    log "[WARN]: Skipping verification of started nodes for 1.8K network"
fi
#Get the started nodes information in temporary file
if [ "$NETWORK_TYPE" != "8K" ]
then
        su netsim -c 'echo ".show started" | /netsim/inst/netsim_shell' > $TEMP/startedNodesDetails.txt
        su netsim -c 'echo ".show allsimnes" | /netsim/inst/netsim_shell' > $TEMP/allNodesDetails.txt

        log "INFO: Checking if directories exist for all started nodes"
        for sim in `ls $PMDIR | egrep -v "TCU02|SIU02|BSC|FrontHaul|TSP|CORE-MGW-15B-16A-UPGIND-V1|CORE-SGSN-42A-UPGIND-V1|PRBS-99Z-16APICONODE-UPGIND-MSRBSV1-LTE99|RNC-15B-16B-UPGIND-V1|EVNFM|VNF-LCM|RAN-VNFM|LTEZ9334-G-UPGIND-V1-LTE95|LTEZ8334-G-UPGIND-V1-LTE96|LTEZ7301-G-UPGIND-V1-LTE97|RNCV6894X1-FT-RBSU4110X1-RNC99|LTE17A-V2X2-UPGIND-DG2-LTE98|LTE16A-V8X2-UPGIND-PICO-FDD-LTE98|VSD|VPP|ML|DOG"`;do
            if [ $sim != "xml_step" ]; then
            #Check in /pms_tmpfs/ for started nodes exists or not.
               for node in `ls $PMDIR/$sim`;do
                   grep "$node" $TEMP/startedNodesDetails.txt > /dev/null
                        if [ ! $? -eq 0 ]
                        then
                           grep "$node" $TEMP/allNodesDetails.txt > /dev/null
                           if [  $? -eq 0 ]
                           then
                              if [ $failureFlag = false ];then
                                 failureFlag=true;
                                 failureFlag_dir=true;
                                 log "ERROR: Few nodes are stopped. Kindly please check"
                              fi
                            log "ERROR: Node $node is not in started state.Please start or delete $node directory from $PMDIR/$sim"
                            else
                              log "INFO: Node $node is not present in server but directory was present"
                           fi
                         fi
               done
             fi

         done
else
    log "[WARN]: Skipping Temporary files Check for 1.8K"
fi
#For MME,FrontHaul and BSC simulations need to check in location /netsim/netsim_dbdir/simdir/netsim/netsimdir/.
if [ "$NETWORK_TYPE" != "8K" ]
then
            for sim in `ls $NETSIMDIR | egrep "SGSN" | egrep -v 'TSP|CORE-MGW-15B-16A-UPGIND-V1|CORE-SGSN-42A-UPGIND-V1|PRBS-99Z-16APICONODE-UPGIND-MSRBSV1-LTE99|RNC-15B-16B-UPGIND-V1|EVNFM|VNF-LCM|RAN-VNFM|LTEZ9334-G-UPGIND-V1-LTE95|LTEZ8334-G-UPGIND-V1-LTE96|LTEZ7301-G-UPGIND-V1-LTE97|RNCV6894X1-FT-RBSU4110X1-RNC99|LTE17A-V2X2-UPGIND-DG2-LTE98|LTE16A-V8X2-UPGIND-PICO-FDD-LTE98|TLS|VTFRADIONODE|5GRADIONODE|VSD|ML|DOG'`;do

                #Check in /netsim/netsim_dbdir/simdir/netsim/netsimdir/ for started nodes exists or not.
                for node in `ls $NETSIMDIR/$sim`;do
                    grep "$node" $TEMP/startedNodesDetails.txt > /dev/null
                        if [ ! $? -eq 0 ] ; then
                            grep "$node" $4TEMP/allNodesDetails.txt > /dev/null
                            if [ $? -eq 0 ] ; then
                                if [ $failureFlag = false ];then
                                failureFlag=true;
                                failureFlag_dir=true;
                                fi
                                log "ERROR: Node $node is not in started state.Please start or delete $node directory from $NETSIMDIR/$sim"
                            else
                                log "INFO: Node $node is not present in server but directory was present"
                            fi
                        fi
                done


            done
        if [ $failureFlag_dir = true ];then
           log "ERROR: Few started nodes do not have directories. Kindly Please check"
        else
            log "INFO: All Started nodes have directories"
        fi
else
    log "[WARN]: Skipping BSC.FrontHaul and MME simulations Check for 1.8K"
fi

#Check the scanners for simulators whether ACTIVE or not
if [ "$NETWORK_TYPE" != "8K" ]
then
        log "INFO: Checking for scanner status"
        for sim in `ls $NETSIMDIR`;do
output=`su netsim -c "/netsim/inst/netsim_pipe<<EOF
.open $sim
.select network
status:pm;
EOF"`
        echo $output | grep -i '\<ACTIVE\>' > $TEMP/scannerDetailsCheck.txt
        if [ -s $TEMP/scannerDetailsCheck.txt ];then
           if [ $failureFlag = false ];then
              failureFlag_scan=true;
           fi
             log "[WARN]: Scanner for nodes in simulator ${sim} is in ACTIVE state.Please change the scanner state to SUSPENDED."
        fi

        done
            if [ $failureFlag_scan = true ];then
               log "[WARN]: Few scanners are in ACTIVE state. Kindly please check"
            else
                log "INFO: All scanners are in deactive state"
            fi

            if [ $failureFlag = true ];then
               log "ERROR: Pre-Health Check Failed."
               exit 207
            else
                log "INFO: Pre-Health Check Completed Successfully."
            fi
            log "INFO: End Processing"
else
    log "[WARN]: Skipping Scanners Check for 1.8K"
fi

#Removing temporary files
rm -rf $TEMP/startedNodesDetails.txt $TEMP/scannerDetailsCheck.txt
