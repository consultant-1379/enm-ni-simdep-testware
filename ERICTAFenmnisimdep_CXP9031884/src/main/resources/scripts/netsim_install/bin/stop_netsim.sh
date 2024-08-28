#!/bin/bash
usage_msg()
{
    message "ERROR:Usage: $0 -m MOUNTPOINT" ERROR
    exit 201
}

function check_args()
{
    if [[ -z "$MOUNTPOINT" ]]
    then
        # Absolute path this script is in. /home/user/bin
        MOUNTPOINT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
        message  "INFO: MOUNTPOINT set to default that is $MOUNTPOINT " INFO
    fi
}

while getopts "m:" arg
do
    case $arg in
        m) MOUNTPOINT="$OPTARG"
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
        MESSAGE="$1 in module stop_netsim.sh "
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
        h=`echo "(($T /3600) % 3600)" | bc`
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



# Main functionality
START=`date +%s%N`
trap "cleanup INT" INT
trap "cleanup EXIT" EXIT
trap "cleanup TERM" TERM
trap "cleanup INT" KILL
trap "cleanup HUP" HUP
if [[ -z "$logFile" ]];
then
    export logFile="$(pwd)/../log/`date +%Y_%m_%d_%H_%M_%S`_stop_netsim.log"
    Flag=1
fi
COPY_LOGFILE_PATH=/tmp/simnet/enm-ni-simdep/logs
if [[ ! -z $Flag ]]
then
    uid=$(id -u)
    if [[ $uid -ne 0 ]]
    then
        message "ERROR: ===================== ERROR!!! =================" ERROR
        message "ERROR: Only root user can execute the stop.sh!        -" ERROR
        message "ERROR: ===================== ERROR!!! =================" ERROR
        exit 208
    fi
fi
check_args

VERSION_RUNNING="`ps -ef | grep platf_indep | grep netsim | awk '{print $8}' | awk -F/ '{print $3}' | head -1`"
if [[ ! -z "$VERSION_RUNNING" ]] && [[ "$VERSION_RUNNING" != "" ]]
then
    if [[ -d /netsim/$VERSION_RUNNING/ ]]
    then
        message "INFO: Stopping netsim version $VERSION_RUNNING " INFO
        su - netsim -c "/netsim/$VERSION_RUNNING/stop_netsim fast" 2>&1 | tee -a $logFile
        exit ${PIPESTATUS[0]}
        fi
fi
message "INFO: Netsim already stopped, not stopping again" INFO
