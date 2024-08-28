#!/bin/bash

# Created by  : Kiran Yakkala
# Created in  : 2015.03.04
##
### VERSION HISTORY
# Ver         : Follow up from gerrit
# Purpose     : Master file to install Netsim
# Dependency  : None
# Description : Master file to install Netsim
# Date        : 04 Mar 2015
# Who         : Kiran Yakkala


#######################################
# Gives usage information
# Arguments:
#   None
# Returns:
#   None
#######################################
function usage_msg()
{
message "$0
-Common Usage Examples:
    $ master.sh -v R28A     # installs netsim version of R28A forcefully, plus verified patches and license
                            # deletes existing other netsim versions from the system
    $ master.sh -r N -d no  # installs latest netsim version available forcefully, plus verified patches and license
                            # keeps existing other netsim versions in the system
    $ master.sh -r N -f no -p no

-Usage: $0 -m mount_point -h host_name -f yes/no -d yes/no -v netsim_version or -r netsim_release_name -p yes/no -l yes/no -c yes/no
    MANDATORY
    -v: specifies version of netsim e.g. N, N_1, N_2
    OR
    -r: specifies release of netsim you want to install e.g. R28A, R27J etc...
    OPTIONALS
    -i: online/offline (default online)
        online -> gets netsim and other files from nexus during rollout
        offline -> gets netsim and other files from a specific path in server which were copied to server before rollout
    -f: yes/no (default yes)
        yes-> installs netsim forcefully
        no-> leaves existing netsim version if requested installation exist
    -d: yes/no (default yes)
        yes-> deletes existing netsim versions
        no-> keeps other existing netsim versions
    -p  yes/no (default yes)
        yes-> installs verified patches only
        no-> does not install any patches
    -l: yes/no (default no)
        yes-> installs netsim license
        no-> doesn not install netsim license
    -m: mountpoint-obsolute path where the scripts executed
    -h: hostname, e.g. netsimlin271
    -c: yes/no (default yes)
        yes-> cleans netsim
        no -> does not clean netsim
    -n: portal/nexus/verfied (default verfied)
        portal-> Downloads patches from portal
        nexus-> Downloads patches from nexus.
        verfied-> Downloads from netsim patch link
    -e: yes/no (default value is no)
        yes -> downloads netsim and patches from ci portal.
        no ->Downloads netsim from netsim page and patches from either nexus (or) netsim page depending on (-n) value
    -s: simulation Version.
        Valid only if nexus mode is yes.

    \n" INFO
    exit 201

}

#######################################
# Validates whether all the manadatary arguments are passed or not
# Arguments:
#   None
# Returns:
#   None
#######################################
function check_args()
{
   if [[ -z "$MOUNTPOINT" ]]
   then
        MOUNTPOINT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
        message  "INFO: MOUNTPOINT set to default that is $MOUNTPOINT " INFO
   elif [[ ! -d $MOUNTPOINT ]]
   then
        message "ERROR: Given mount point $MOUNTPOINT not exists" ERROR
        exit 203
   fi
   if [[ -z "$HOSTNAME" ]]
   then
        HOSTNAME=hostname
        message "INFO: HOSTNAME is not specified set to default that is $HOSTNAME " INFO
    fi
    if [[ -z "$VERSION" &&  -z "$RELEASE" ]]
    then
        message "ERROR: You must say what version  or release to install " ERROR
        usage_msg
    elif [[ "$VERSION" &&  "$RELEASE" ]]
    then
        message "ERROR: You must say either version  or release to install " ERROR
        usage_msg
    fi
    if [[ -z "$FORCE" ]]
    then
        FORCE="yes"
        message "INFO: Default value for f is set to $FORCE " INFO
    elif [[  "$FORCE" != "yes"  &&  "$FORCE" != "no"  ]]
    then
        message "ERROR: Invalid $FORCE argument passed for the force(-f) option" ERROR
        message "ERROR: Valid values for force(-f) are yes or no " ERROR
        exit 203
    fi
    if [[ -z "$DELETE" ]]
    then
        DELETE="yes"
        message "INFO: Default value for d is set to $DELETE " INFO
    elif [[ "$DELETE" != "yes" && "$DELETE" != "no" ]]
    then
        message "ERROR: Valid values for delete(-d) are yes or no " ERROR
        exit 203
    fi
    if [[ -z "$PATCH" ]]
    then
        PATCH="yes"
        message "INFO: Default value for p is set to $PATCH " INFO
    elif [[ "$PATCH" != "yes" && "$PATCH" != "no" ]]
    then
        message "ERROR: Valid values for patch(-p) are yes or no " ERROR
        exit 203
    fi
    if [[ -z "$LICENSE" ]]
    then
        LICENSE="no"
        message "INFO: Default value for l is set to $LICENSE " INFO
    elif [[ "$LICENSE" != "yes" && "$LICENSE" != "no" ]]
    then
        message "ERROR: Valid values for License(-l) is yes or no " ERROR
        exit 203
    fi
    if [[ -z "$CLEANNETSIM" ]]
    then
        CLEANNETSIM="yes"
        message "INFO: Default value for clean netsim is set to $CLEANNETSIM " INFO
    elif [[ "$CLEANNETSIM" != "yes" && "$CLEANNETSIM" != "no" ]]
    then
        message "ERROR: Valid values CleanNetsim(-c) is yes or no  " ERROR
        exit 203
    fi
    if [[ -z "$PATCHMODE" ]]
    then
        PATCHMODE="verified"
        message "INFO: Default value for patch mode is set to $PATCHMODE " INFO
    elif [[ "$PATCHMODE" != "portal" && "$PATCHMODE" != "nexus" && "$PATCHMODE" != "verified" ]]
    then
        message "ERROR: Valid values Patch mode (-n) is portal or nexus or verified  " ERROR
        exit 203
    fi
    if [[ -z "$CIPORTAL" ]]
    then
        CIPORTAL="no"
        message "INFO: Default value for ci portal is set to $CIPORTAL " INFO
    elif [[ "$CIPORTAL" != "yes" && "$CIPORTAL" != "no" ]]
    then
        message "ERROR: Valid values ciportal(-e) is yes or no  " ERROR
        exit 203
    fi
    if [[ -z "$SIMVERSION" ]]
    then
        SIMVERSION=""
        message "INFO: Default value for sim version is set to $SIMVERSION " INFO
    fi
    if [[ -z "$INSTALLTYPE" ]]
    then
       INSTALLTYPE="online"
       message "INFO: Default value for $INSTALLTYPE is set to $INSTALLTYPE " INFO
    fi
    if [[ -z "$ROLLOUTTYPE" ]]
    then
       ROLLOUTTYPE="normal"
       message "INFO: Default value for $INSTALLTYPE is set to $INSTALLTYPE " INFO
    fi
}

while getopts "m:v:f:h:d:r:p:l:c:n:s:e:i:g:" arg
do
    case $arg in
        m) MOUNTPOINT="$OPTARG"
        ;;
        v) VERSION="$OPTARG"
           NETSIM_VERSION=$VERSION
        ;;
        f) FORCE="$OPTARG"
        ;;
        h) HOSTNAME="$OPTARG"
        ;;
        d) DELETE="$OPTARG"
        ;;
        r) RELEASE="$OPTARG"
        ;;
        p) PATCH="$OPTARG"
        ;;
        l) LICENSE="$OPTARG"
        ;;
        c) CLEANNETSIM="$OPTARG"
        ;;
        n) PATCHMODE="$OPTARG"
        ;;
        s) SIMVERSION="$OPTARG"
        ;;
        e) CIPORTAL="$OPTARG"
        ;;
        i) INSTALLTYPE="$OPTARG"
        ;;
        g) ROLLOUTTYPE="$OPTARG"
        ;;
       \?) usage_msg
        ;;
    esac
done

function message ()
{

    local MESSAGE="$1"
    local TYPE=$2
    COLOR=$white
    if [[ "$TYPE" == "ERROR" ]]
    then
        COLOR=$red
        MESSAGE="$1 in module master.sh "
    fi
    if [[ "$TYPE" == "LINE" ]]
    then
        COLOR=$magenta
    fi
    if [[ "$TYPE" == "WARNING" ]]
    then
        COLOR=$yellow
    fi
    if [[ "$TYPE" == "SUMMARY" ]]
    then
        COLOR=$green
    fi
    if [[ "$TYPE" == "SCRIPT" ]]
    then
        COLOR=$cyan
    fi
    if [[ `echo "$MESSAGE" | egrep "^INFO:|^ERROR:|^WARNING:"` ]]
    then
        local FORMATTED_DATE="`date | awk '{print $2 "_" $3}'`"
        local FORMATTED_TIME="`date | awk '{print $4}'`"
        MESSAGE="[$FORMATTED_DATE $FORMATTED_TIME] $MESSAGE"
    fi
    echo -en $COLOR
    echo -en "$MESSAGE \n" 2>&1 | tee -a $logFile
    echo -en $white
}

function cleanup ()
{
    SCRIPT_EXIT_CODE=$?
    EXIT_REASON="$1"
    trap - INT TERM EXIT
    END=`date +%s%N`
    T=`echo "scale=8; ($END - $START) / 1000000000" | bc`
    h=`echo "(($T /3600) % 3600)" | bc`
    m=`echo "(($T / 60) % 60)" | bc`
    s=`echo "($T % 60)" | bc`
    if [[ $SCRIPT_EXIT_CODE -ne 0 ]]
    then
        EXIT_TYPE="ERROR"
        Complete_Exit="exited"
    else
        EXIT_TYPE="INFO"
        Complete_Exit="completed"
    fi
    message "$EXIT_TYPE: The script $Complete_Exit with exit code $SCRIPT_EXIT_CODE" $EXIT_TYPE
    if [[ "$EXIT_REASON" != "EXIT" ]]
    then
        message "ERROR: The script didn't exit by itself, it exited with signal $EXIT_REASON" ERROR
    fi
    message "INFO: Output log stored to $logFile" INFO
    message "INFO: The output log file is also copied to $COPY_LOGFILE_PATH \n" INFO
    printf "Total Execution Time : %02d hours %02d minutes %.8f seconds \n" $h $m $s  |tee -a $logFile
    copy_logfile

    # Remove traps again
    trap - TERM INT EXIT
    # Exit
    exit
}


#######################################
# Veryfies whether argument passed is initialized or not
# Arguments:
#   Variable
# Returns:
#   None
#######################################
function requires_variable ()
{
    local VARTEST=`eval echo \\$$1`
    if [[ -z $VARTEST ]]
    then
        message "ERROR: The variable $1 wasn't set in any of your config files, please check why not" ERROR
        exit 202
    fi
}

#######################################
# Configures ntp client oon given HOSTNAME
# Arguments:
#   none
# Returns:
#   None
#######################################
function setup_ntp_client_netsim()
{
    $MOUNTPOINT/setup_ntp_client.sh -m $MOUNTPOINT 2>&1|tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Error in setup_ntp_client.sh" ERROR
        exit 207
    fi
}

#######################################
# Derives required NEtsim releases and invlokes netsim install module
# Arguments:
#   none
# Returns:
#   None
#######################################
function install_netsim_internal ()
{
    local SERVER="$1"
    local NETSIM_VERSION="$2"
    local FORCE="$3"
    if [[ "$NETSIM_VERSION" == "N" ]]
    then
        TEMP_NETSIM_VERSION=`$MOUNTPOINT/getNetsimVersion.pl -t=r -v=1 2>&1`
    elif [[ "$NETSIM_VERSION" == "N_1" ]]
    then
        TEMP_NETSIM_VERSION=`$MOUNTPOINT/getNetsimVersion.pl -t=r -v=2 2>&1`
    elif [[ "$NETSIM_VERSION" == "N_2" ]]
    then
        TEMP_NETSIM_VERSION=`$MOUNTPOINT/getNetsimVersion.pl -t=r -v=3 2>&1`
    elif [[ ${#NETSIM_VERSION} == 4 && "$NETSIM_VERSION" == R* ]]
    then
        TEMP_NETSIM_VERSION=$NETSIM_VERSION
    else
        if [[ "$VERSION" ]]
        then
            message "ERROR: Don't know what version $NETSIM_VERSION is, please use N, N_1 or N_2 " ERROR
            exit 203
        else
            message "ERROR: Don't know what release $NETSIM_VERSION is, please specify valid NETSIM release " ERROR
            exit 203
        fi
    fi
    ACTUAL_NETSIM_VERSION=`echo $TEMP_NETSIM_VERSION | sed 's,^ *,,; s, *$,,'`
    if [[ ${#ACTUAL_NETSIM_VERSION}  -ne 4  ]]
    then
        echo "$TEMP_NETSIM_VERSION" |tee -a $logFile
        message "ERROR: Fetching netsim version failed" ERROR
        exit 207
    fi
    message "INFO: Installing netsim $ACTUAL_NETSIM_VERSION on $HOSTNAME" INFO
    message "INFO: Configuring ntp setup " INFO
    setup_ntp_client_netsim
    if [[ $? -ne 0 ]]
    then
        message "ERROR: Something wen't wrong configuring ntp setup, retrying again" ERROR
        setup_ntp_client_netsim
        if [[ $? -ne 0 ]]
        then
            message "ERROR: Failed to call setup_ntp_client_netsim, check output above" ERROR
            exit 207
        fi
    fi
    message "INFO: Configuring internal ssh " INFO
    $MOUNTPOINT/setup_internal_ssh.sh $ROLLOUTTYPE 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Something wen't wrong configuring internal ssh, retrying again" ERROR
        $MOUNTPOINT/setup_internal_ssh.sh $ROLLOUTTYPE 2>&1 |tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Error in setup_internal_ssh.sh" ERROR
            exit 207
        fi
    fi
    $MOUNTPOINT/install_netsim.sh -m $MOUNTPOINT -r $ACTUAL_NETSIM_VERSION -f $FORCE -d $DELETE -p $PATCH -l $LICENSE -n $PATCHMODE -s $SIMVERSION -e $CIPORTAL -i $INSTALLTYPE
    STATUS=$?
    if [[ ${STATUS} -ne 0 ]]
    then
        message "ERROR: Something wen't wrong installing netsim, retrying again" ERROR
        $MOUNTPOINT/install_netsim.sh -m $MOUNTPOINT -r $ACTUAL_NETSIM_VERSION -f $FORCE -d $DELETE -p $PATCH -l $LICENSE -n $PATCHMODE -s $SIMVERSION -e $CIPORTAL -i $INSTALLTYPE
        NEW_STATUS=$?
        if [[ ${NEW_STATUS} -ne 0 ]]
        then
            message "ERROR: Something wen't wrong installing netsim, check output above " ERROR
            exit "${NEW_STATUS}"
        else
             message "INFO: Netsim installation is successful after retrying" INFO
             if [[ "$CLEANNETSIM" == "yes" ]]
             then
                 message "INFO: Netsim is being cleaned" INFO
                 rm -rf /tmp/cleanVapp.log;
                 rm -rf /tmp/cleanNetsim.log;
                 chmod 777 $(pwd)/../../simdep/utils/ossmaster/;
                 su - netsim -c "cd $(pwd)/../../simdep/utils/ossmaster/; ./runCleanVapp.sh -n"
                 EXIT_CODE=$?
                 if [ $EXIT_CODE != 0 ]; then
                    echo "ERROR: Unable to start NETSim successfully!!!" | tee -a $VAPP_LOGFILE
                    echo "ERROR: Shutting down simdep for NETSim Install ERROR!!!" | tee -a $VAPP_LOGFILE
                    exit -1
                fi
             fi
             message "INFO: Netsim install finished, Creating netsimprmn,prmnresponse folders in /dev/" INFO
             mkdir -p /dev/netsimprmn /dev/prmnresponse;chown -R  netsim:netsim /dev/netsimprmn /dev/prmnresponse
             if [[ ! -d "/dev/netsimprmn" ]] || [[ ! -d "/dev/prmnresponse" ]]
             then
                mkdir -p /dev/netsimprmn /dev/prmnresponse;chown -R  netsim:netsim /dev/netsimprmn /dev/prmnresponse
             fi
             message "INFO: Stopping netsim for running setup_fd_server.sh" INFO
             $MOUNTPOINT/stop_netsim.sh -m $MOUNTPOINT
             if [[ ${PIPESTATUS[0]} -ne 0 ]]
             then
                 message "ERROR: Error in stopping netsim" ERROR
                 exit 207
             fi
             message "INFO: Running setup_fd_server.sh " INFO
             /netsim/inst/bin/setup_fd_server.sh 2>&1 |tee -a $logFile
             if [[ ${PIPESTATUS[0]} -ne 0 ]]
             then
                 message "ERROR: Error in setup_fd_server.sh" ERROR
                 exit 207
             fi
             $MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
             if [[ ${PIPESTATUS[0]} -ne 0 ]]
             then
             message "ERROR: Error in start_netsim" ERROR
             exit 207
             fi
             message "INFO:========================DONE=============================" INFO
#            exit 0
             check_NetsimStart=`su netsim -c "echo -e '\n' | /netsim/inst/netsim_shell"`
             if [[ ! -z $check_NetsimStart ]] && ( [[ $check_NetsimStart == *"NETSim not started"* ]] || [[ $check_NetsimStart == *"restart_netsim"* ]] || [[ $check_NetsimStart == *"NETSim is not started"* ]] )
             then
                 message "ERROR: Netsim was not started properly" ERROR
                 message "INFO: Removing servernode file to start netsim" INFO
                 rm -rf /netsim/saveconfigurations/*_server_node
                 if [ $? != 0 ]
                 then
                   message "ERROR: Failed to removed server_node in saveconfigurations" ERROR
                   exit 207
                 fi
                 #$MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
                 su netsim -c "/netsim/inst/restart_netsim"
                 if [[ $? != 0 ]]
                 then
                     message "ERROR: Error in start_netsim" ERROR
                     exit 207
                 fi
                 check_Start=`su netsim -c "echo -e '\n' | /netsim/inst/netsim_shell"`
                 if [[ ! -z $check_Start ]] && ( [[ $check_Start == *"NETSim not started"* ]] || [[ $check_Start == *"restart_netsim"* ]] || [[ $check_Start == *"NETSim is not started"* ]] )
                 then
                   message "ERROR: Netsim was not started properly" ERROR
                   message "INFO: Removing servernode file to start netsim" INFO
                   rm -rf /netsim/saveconfigurations/*_server_node
                   if [ $? != 0 ]
                   then
                       message "ERROR: Failed to removed server_node in saveconfigurations" ERROR
                       exit 207
                   fi
                   #$MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
                   su netsim -c "/netsim/inst/restart_netsim"
                   if [[ $? != 0 ]]
                   then
                       message "ERROR: Error in start_netsim" ERROR
                       exit 207
                   fi
                fi
             fi
             message "INFO:========================DONE=============================" INFO
             exit 0             
        fi
    else
        if [[ "$CLEANNETSIM" == "yes" ]]
        then
             message "INFO: Netsim is being cleaned" INFO
            rm -rf /tmp/cleanVapp.log;
            rm -rf /tmp/cleanNetsim.log;
            chmod 777 $(pwd)/../../simdep/utils/ossmaster/;
            su - netsim -c "cd $(pwd)/../../simdep/utils/ossmaster/; ./runCleanVapp.sh -n"
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]; then
                echo "ERROR: Unable to start NETSim successfully!!!" | tee -a $VAPP_LOGFILE
                echo "ERROR: Shutting down simdep for NETSim Install ERROR!!!" | tee -a $VAPP_LOGFILE
                exit -1
            fi

        fi
        message "INFO: Netsim install finished, Creating netsimprmn prmnresponse folders in /dev/" INFO
        mkdir -p /dev/netsimprmn /dev/prmnresponse;chown -R  netsim:netsim /dev/netsimprmn /dev/prmnresponse
        if [[ ! -d "/dev/netsimprmn" ]] || [[ ! -d "/dev/prmnresponse" ]]
        then
            mkdir -p /dev/netsimprmn /dev/prmnresponse;chown -R  netsim:netsim /dev/netsimprmn /dev/prmnresponse
        fi
        message "INFO: Stopping netsim for running setup_fd_server.sh" INFO
        $MOUNTPOINT/stop_netsim.sh -m $MOUNTPOINT
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Error in stopping netsim" ERROR
            exit 207
        fi
        message "INFO: Running setup_fd_server.sh " INFO
        /netsim/inst/bin/setup_fd_server.sh 2>&1 |tee -a $logFile
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Error in setup_fd_server.sh" ERROR
            exit 207
        fi
        $MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
        if [[ ${PIPESTATUS[0]} -ne 0 ]]
        then
            message "ERROR: Error in start_netsim" ERROR
            exit 207
        fi
        message "INFO:========================DONE=============================" INFO
#       exit 0
        check_NetsimStart=`su netsim -c "echo -e '\n' | /netsim/inst/netsim_shell"`
        if [[ ! -z $check_NetsimStart ]] && ( [[ $check_NetsimStart == *"NETSim not started"* ]] || [[ $check_NetsimStart == *"restart_netsim"* ]] || [[ $check_NetsimStart == *"NETSim is not started"* ]] )
        then
            message "ERROR: Netsim was not started properly" ERROR
            message "INFO: Removing servernode file to start netsim" INFO
            rm -rf /netsim/saveconfigurations/*_server_node
            if [ $? != 0 ]
            then
                 message "ERROR: Failed to removed server_node in saveconfigurations" ERROR
                 exit 207
             fi
             #$MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
             su netsim -c "/netsim/inst/restart_netsim"
             if [[ $? != 0 ]]
             then
                 message "ERROR: Error in start_netsim" ERROR
                 exit 207
             fi
             check_Start=`su netsim -c "echo -e '\n' | /netsim/inst/netsim_shell"`
             if [[ ! -z $check_Start ]] && ( [[ $check_Start == *"NETSim not started"* ]] || [[ $check_Start == *"restart_netsim"* ]] || [[ $check_Start == *"NETSim is not started"* ]] )
             then
                  message "ERROR: Netsim was not started properly" ERROR
                  message "INFO: Removing servernode file to start netsim" INFO
                  rm -rf /netsim/saveconfigurations/*_server_node
                  if [ $? != 0 ]
                  then
                       message "ERROR: Failed to removed server_node in saveconfigurations" ERROR
                       exit 207
                  fi
                  #$MOUNTPOINT/start_netsim.sh -m $MOUNTPOINT
                  su netsim -c "/netsim/inst/restart_netsim"
                  if [[ $? != 0 ]]
                  then
                       message "ERROR: Error in start_netsim" ERROR
                       exit 207
                  fi
             fi
         fi
         message "INFO:========================DONE=============================" INFO
         exit 0
    fi
}

function install_netsim_config_force ()
{
    if [[ "$VERSION" ]]
    then
        message "INFO: Fetching corresponding release number for version $VERSION " INFO
        install_netsim_internal $HOSTNAME $VERSION $FORCE
    elif [[ "$RELEASE" ]]
    then
        install_netsim_internal $HOSTNAME $RELEASE $FORCE
    fi
}

#copies log file to another location
function copy_logfile ()
{
    mkdir -p $COPY_LOGFILE_PATH 2>&1 |tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: mkdir failed to create $COPY_LOGFILE_PATH " ERROR
        exit 206
    fi
    cp $logFile $COPY_LOGFILE_PATH 2>&1 | tee -a $logFile
    if [[ ${PIPESTATUS[0]} -ne 0 ]]
    then
        message "ERROR: Failed to copy the log file to $COPY_LOGFILE_PATH " ERROR
        exit 206
    fi
}

#######################################
# Verifies currently ongoing netsim installs and stops the ongoing installation
# Arguments:
#   none
# Returns:
#   None
#######################################
function  kill_ongoing_ni_processes ()
{
    message "INFO: Verifying currently ongoing netsim installs and stops the ongoing installation." INFO
    unbundle_processes=`ps -ef  | grep "Unbundle.sh" | grep -v grep | awk '{ print $2 }'`
    echo $unbundle_processes | while read processid
    do
        if [[ $processid != "" ]]
        then
            message "INFO: Killing unbundle process $processid \n" INFO
            `pkill -TERM -P $processid` 2>&1 | tee -a $logFile
        fi
    done
    for processid in $(pidof -x master.sh)
    do
        if [[ $processid != $$ ]]
        then
            message "INFO: Killing $0 process $processid \n" INFO
            `pkill -TERM -P $processid` 2>&1 | tee -a $logFile
        fi
    done
    message "INFO: Verified ongoing netsim installs, (and killed the any ongoing installation)." INFO
}
trap "cleanup INT" INT
trap "cleanup EXIT" EXIT
trap "cleanup TERM" TERM
trap "cleanup INT" KILL
trap "cleanup HUP" HUP
START=`date +%s%N`
export logFile="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../log/`date +%Y_%m_%d_%H_%M_%S`_master_ni.log
COPY_LOGFILE_PATH=/tmp/simnet/enm-ni-simdep/logs/
uid=$(id -u)
if [[ $uid -ne 0 ]]
then
    message "ERROR: ===================== ERROR!!! ===========================" ERROR
    message "ERROR: Only root user can execute the master.sh!                -" ERROR
    message "ERROR: ===================== ERROR!!! ===========================" ERROR
    exit 208
fi

mkdir -p /var/netsim
message "INFO: Validating arguments " INFO
check_args
message "INFO: Arguments validation completed " INFO
kill_ongoing_ni_processes
SSH="/usr/bin/ssh -o StrictHostKeyChecking=no"
install_netsim_config_force
