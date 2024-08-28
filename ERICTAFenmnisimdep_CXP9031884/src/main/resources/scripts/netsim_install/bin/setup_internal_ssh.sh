#!/bin/bash
function message ()
{

    local MESSAGE="$1"
    local TYPE=$2
    COLOR=$white
    if [[ "$TYPE" == "ERROR" ]]
    then
        COLOR=$red
        MESSAGE="$1 in module setup_internal_ssh.sh "
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
    if [[ $SCRIPT_EXIT_CODE -ne 0 ]]
    then
        message "ERROR: The script exited with exit code $SCRIPT_EXIT_CODE" ERROR
    fi
    if [[ "$EXIT_REASON" != "EXIT" ]]
    then
        message "ERROR: The script didn't exit by itself, it exited with signal $EXIT_REASON" ERROR
    fi
    if [[ ! -z $Flag ]]
    then
        END=`date +%s%N`
        T=`echo "scale=8; ($END - $START) / 1000000000" | bc`
        h=`echo "(($T / 3600) % 3600)" | bc`
        m=`echo "(($T / 60) % 60)" | bc`
        s=`echo "($T % 60)" | bc`
        message "INFO: Output log stored to $logFile" INFO
        message "INFO: The output log file is also copied to $COPY_LOGFILE_PATH \n" INFO
        printf "Total Execution Time : %02d hours %02d minutes %.8f seconds \n" $h $m $s  |tee -a $logFile
        copy_logfile
    fi
    # Remove traps again
    trap - TERM INT EXIT
    # Exit
    exit $SCRIPT_EXIT_CODE
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


usage() {
    echo "ERROR: Invalid arguments"
    echo "Example: $0 online or $0 offline"
    exit 1
}
[[ $# -ne 1 ]] && usage


rolloutType=$1
HOSTNAME=`hostname`
#IP=`getent hosts $HOSTNAME | awk '{print $1}'`
IP=`hostname -i`

SSHD_ENTRY="ListenAddress $IP"
SSHD_ENTRY2="ListenAddress 127.0.0.1"
START=`date +%s%N`
trap "cleanup INT" INT
trap "cleanup EXIT" EXIT
trap "cleanup TERM" TERM
trap "cleanup INT" KILL
trap "cleanup HUP" HUP
if [[ -z "$logFile" ]];
then
    export logFile="$(pwd)/../log/`date +%Y_%m_%d_%H_%M_%S`_setup_internal_ssh.log"
    Flag=1
fi
COPY_LOGFILE_PATH=/tmp/simnet/enm-ni-simdep/logs
if [[ ! -z $Flag ]]
then
    uid=$(id -u)
    if [[ $uid -ne 0 ]]
    then
        message "ERROR: =================== ERROR!!! =============================" ERROR
        message "ERROR: Only root user can execute the setup_internal_ssh.sh!    -" ERROR
        message "ERROR: =================== ERROR!!! =============================" ERROR
        exit 208
    fi
fi
if [[ ${rolloutType} = "GCP" ]]
then
   HOSTIP=`ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
   SSHD_ENTRY3="ListenAddress $HOSTIP"

   if [[ ! `grep "^$SSHD_ENTRY$" /etc/ssh/sshd_config` ]] || [[ ! `grep "^$SSHD_ENTRY2$" /etc/ssh/sshd_config` ]] || [[ ! `grep "^$SSHD_ENTRY3$" /etc/ssh/sshd_config` ]]
   then
       echo "INFO: Setting up Internal SSH"
       cat /etc/ssh/sshd_config | grep -v "^ListenAddress" > /etc/ssh/sshd_config.tmp
       mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
       if [[ $? -ne 0 ]]
       then
           message "ERROR: Moving sshd_config.tmp from /etc/ssh to /etc/ssh/sshd_config failed " ERROR
           exit 206
       fi
       echo "$SSHD_ENTRY" >> /etc/ssh/sshd_config
       echo "$SSHD_ENTRY2" >> /etc/ssh/sshd_config
       echo "$SSHD_ENTRY3" >> /etc/ssh/sshd_config
       #pkill -HUP sshd
       service sshd restart
    fi
else
   if [[ ! `grep "^$SSHD_ENTRY$" /etc/ssh/sshd_config` ]] || [[ ! `grep "^$SSHD_ENTRY2$" /etc/ssh/sshd_config` ]]
   then
       echo "INFO: Setting up Internal SSH"
       cat /etc/ssh/sshd_config | grep -v "^ListenAddress" > /etc/ssh/sshd_config.tmp
       mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
       if [[ $? -ne 0 ]]
       then
           message "ERROR: Moving sshd_config.tmp from /etc/ssh to /etc/ssh/sshd_config failed " ERROR
           exit 206
       fi
       echo "$SSHD_ENTRY" >> /etc/ssh/sshd_config
       echo "$SSHD_ENTRY2" >> /etc/ssh/sshd_config
       #pkill -HUP sshd
       service sshd restart
    fi
fi
