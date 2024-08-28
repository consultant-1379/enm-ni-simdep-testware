#!/bin/bash
#
##############################################################################
#     File Name     : installPatch.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : installs necessary patch on netsim box.
#     Date Created  : 12 April 2018
###############################################################################
#
###################################################################
#Variables
###################################################################
deltaContent=$@

cd /netsim/simdepContents
netsimPatchesContentFile=`ls|grep .content | grep -i netsimpatches`
netsimPatchesUrlsFile=`ls|grep .Urls | grep -i netsimpatches`
cat deltaContentUrls.content >> $netsimPatchesContentFile
cat deltaContentUrls.content >> $netsimPatchesUrlsFile

rm -rf deltaContentUrls.content
deltaContent=`echo $deltaContent | sed -e "s/\[//g" | sed -e "s/\]//g"`

IFS=' , ' read -r -a deltaContentArray <<< "$deltaContent"

cd /netsim/simdepContents/

netsimPatchesContentFile=$(ls|grep .content | grep -i netsimpatches)

cd /netsim/inst
echo "deltacontent array is ${deltaContentArray[@]}"
for deltaContents in  "${deltaContentArray[@]}"
do
    patch=`grep $deltaContents /netsim/simdepContents/$netsimPatchesContentFile`
    echo "patch is $patch"
    rm -rf patchOutput.txt
    IFS='/' read -ra ADDR <<< "$patch"
    patchName=${ADDR[11]}
    su netsim -c "wget --no-proxy -O $patchName.zip $patch"
    su netsim -c "echo '.install patch $patchName.zip'|./netsim_shell > patchOutput.txt"
    cat patchOutput.txt
    OK_IN_OUTPUT=`tail -n 1 patchOutput.txt | grep OK`
    if [[ $OK_IN_OUTPUT = "OK" ]]
    then
        echo "INFO: Patch is successfully installed"
    else
        echo "ERROR: Patch is not installed properly. Please install again"
        exit 1
    fi
done
