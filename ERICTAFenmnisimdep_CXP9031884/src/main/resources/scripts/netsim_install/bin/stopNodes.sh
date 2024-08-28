#!/bin/sh

output=`su netsim -c "echo -e '.server stop all\n' | /netsim/inst/netsim_shell"`
if [[ $output != *"OK"* ]]
then
   echo "ERROR: unable to stop the nodes"
   echo $output
   exit
fi
echo $output