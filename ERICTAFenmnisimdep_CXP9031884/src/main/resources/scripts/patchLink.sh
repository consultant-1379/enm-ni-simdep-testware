#!/bin/sh

patchLink=$1

if [[ $# -ne 1 ]]
then
       echo "ERROR: Invalid parameters"
          echo "INFO: ./$0 patchlink"
             exit 1
fi
if [[ $patchLink = "null" ]]
then 
    echo "INFO: PatchLink is not passed, No need to install"
     exit
 fi
patchName=`echo $patchLink | rev | awk -F "/" '{print $1}' | rev`

echo $patchName

cd /netsim/inst
wget -O $patchName $patchLink
su netsim -c "echo \".install patch $patchName force\" | ./netsim_shell"
