#!/bin/sh

set -o pipefail

if [[ $# -ne 1 ]]
then
   echo "ERROR: Invalid Arguments"
   echo "INFO: $0 cmd"
   echo "Example: $0 'sh /netsim/inst/start_all_simne.sh'"
   echo "Example: $0 'ls /netsim/netsimdir/'"
   exit 1
fi

execute=$1

if [[ $execute == "NotPassed" ]] || [[ -z $execute ]]
then
   echo "ERROR: Command to execute was not passed"
   exit 1
fi

echo "INFO: Executing $execute cmd"
su netsim -c "$execute"

if [[ $? -ne 0 ]]
then
   echo "ERROR: Cmd execution was not sucessfull on $HOSTNAME"
   exit 1
fi