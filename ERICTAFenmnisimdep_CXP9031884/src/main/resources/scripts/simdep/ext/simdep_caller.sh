#!/bin/bash

#env variables
scriptName=`basename $0`

INSTALL_DIR="/var/simnet/simdep"
SCRIPT_CALL_DIR="${INSTALL_DIR}/bin/"
SCRIPT_NAME_TO_CALL="invokeSimNetDeployer.pl"

# Colors
black='\E[30;40m'
red='\E[31;40m'
green='\E[32;40m'
yellow='\E[33;40m'
blue='\E[34;40m'
magenta='\E[35;40m'
cyan='\E[36;40m'
white='\E[37;40m'

usage_msg()
{
        echo "Usage: $0" 
        exit 1
}

function message ()
{

        local MESSAGE="$1"
        local TYPE=$2

        COLOR=$white
        if [[ "$TYPE" == "ERROR" ]]
        then
                COLOR=$red
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
        echo -en "$MESSAGE"
        echo -en $white

}

message "INFO:-$scriptName ..starting execution of $scriptName \n" INFO


[[ -f ${SCRIPT_CALL_DIR}$SCRIPT_NAME_TO_CALL ]] && chmod u+x ${INSTALL_DIR}/bin/$SCRIPT_NAME_TO_CALL \
	||  { message "ERROR:-$scriptName: Could not find file: ${SCRIPT_CALL_DIR}$SCRIPT_NAME_TO_CALL \n" ERROR >&2; exit 1; }

cd ${SCRIPT_CALL_DIR} && ./$SCRIPT_NAME_TO_CALL \
	||  { message "ERROR:-$scriptName: Execution failed!. See above error message.\n" ERROR >&2; exit 1; }

message "INFO:-$scriptName: ..ended execution of $scriptName \n" INFO

echo "----------"
echo "----------"

