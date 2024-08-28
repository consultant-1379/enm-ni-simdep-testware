#!/bin/bash

# Env variables
SIMSERVER=ftp.athtem.eei.ericsson.se
SIMSERVER_USER=simguest
SIMSERVER_PASS=simguest

INSTALLDIR=/var/simnet/

SIMDEP_ARCHIVE_FILE="simdep.tar.gz"
SIMDEP_FOLDER="simdep"
SIMDEP_INVOKER_SCRIPT=""

# Colors
black='\E[30;40m'
red='\E[31;40m'
green='\E[32;40m'
yellow='\E[33;40m'
blue='\E[34;40m'
magenta='\E[35;40m'
cyan='\E[36;40m'
white='\E[37;40m'

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


scriptName=`basename $0`
message "INFO:-$scriptName: ..starting execution of $scriptName \n" INFO

message "INFO:-$scriptName: starting to download $SIMDEP_ARCHIVE_FILE \n" INFO

if [[ -d $INSTALLDIR  ]]
then
	rm -rf $INSTALLDIR \
	||  { message "ERROR:-$scriptName: Could not delete directory : $INSTALLDIR \n" ERROR >&2; exit 1; }
fi

mkdir -p $INSTALLDIR  \
	||  { message "ERROR:-$scriptName: Could not create directory : $INSTALLDIR \n" ERROR >&2; exit 1; }

( cd $INSTALLDIR \
	&& /usr/bin/curl -u simguest:simguest -O ftp://ftp.athtem.eei.ericsson.se/TEP/qfatonu/download/$SIMDEP_ARCHIVE_FILE ) \
	||  { message "ERROR:-$scriptName: SIMDEP_ARCHIVE_FILE=$SIMDEP_ARCHIVE_FILE does not exist \n" ERROR >&2; exit 1; }

message "INFO:-$scriptName: ended $SIMDEP_ARCHIVE_FILE download operation succesfully! \n" INFO

message "INFO:-$scriptName: starting to untar ${SIMDEP_ARCHIVE_FILE}... \n" INFO

if [[ -f $INSTALLDIR/$SIMDEP_ARCHIVE_FILE ]]
then
	( cd $INSTALLDIR && tar -xf $SIMDEP_ARCHIVE_FILE ) \
		||  { message "ERROR:-$scriptName: SIMDEP_ARCHIVE_FILE=$SIMDEP_ARCHIVE_FILE does not exist \n" ERROR >&2; exit 1; }
fi

if [[ -d $INSTALLDIR/$SIMDEP_FOLDER ]]
then
	message "INFO:-$scriptName: SIMDEP_FOLDER=$INSTALLDIR${SIMDEP_FOLDER} successfully created! \n" INFO
fi

message "INFO:-$scriptName: ended $SIMDEP_ARCHIVE_FILE untar operation succesfully! \n" INFO

message "INFO:-$scriptName: ..ended execution of $scriptName \n" INFO

