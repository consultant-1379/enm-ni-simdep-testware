#!/bin/bash
#
##############################################################################
#     File Name     : installPatch.sh
#     Author        : Sravanthi Pasumarthi
#     Description   : installs necessary patch on netsim box.
#     Date Created  : 03 January 2019
###############################################################################
#
###################################################################
#Variables
###################################################################
deltaContent=$@

rm -rf oldnetsimPatchesContentFile
rm -rf oldnetsimPatchesUrlsFile
cd /netsim/simdepContents
netsimPatchesContentFile=`ls|grep .content | grep -i netsimpatches`
netsimPatchesUrlsFile=`ls | grep .Urls | grep -i netsimpatches`


touch oldnetsimPatchesContentFile
touch oldnetsimPatchesUrlsFile


cat $netsimPatchesContentFile > oldnetsimPatchesContentFile

cat NetsimPatches_CXP9032769.Urls > oldnetsimPatchesUrlsFile

oldfile=`cat oldnetsimPatchesContentFile`
deltaContent=`echo $deltaContent | sed -e "s/\[//g" | sed -e "s/\]//g"`

IFS=' , ' read -r -a deltaContentArray <<< "$deltaContent"

cd /netsim/simdepContents/


cd /netsim/inst
echo "deltacontent array is ${deltaContentArray[@]}"
for deltaContents in  "${deltaContentArray[@]}"
do
   patchName=`grep $deltaContents /netsim/simdepContents/deltaContentUrls.content`
   patch=$deltaContents
   echo "patch is $patch"
    rm -rf patchOutput.txt
    su netsim -c "wget --no-proxy -O $patch.zip $patchName"
    su netsim -c "echo '.install patch $patch.zip'|./netsim_shell > patchOutput.txt"
    cat patchOutput.txt
    OK_IN_OUTPUT=`tail -n 1 patchOutput.txt | grep OK`
    if [[ $OK_IN_OUTPUT = "OK" ]]
    then
        if  grep $deltaContents /netsim/simdepContents/$netsimPatchesContentFile ;then
                echo "patch is already installed"
        else
                echo $patchName >> /netsim/simdepContents/$netsimPatchesContentFile
                echo $patchName >> /netsim/simdepContents/NetsimPatches_CXP9032769.Urls
                echo "INFO: Patch is successfully installed"
        fi
    else
        cat oldnetsimPatchesContentFile >  /netsim/simdepContents/$netsimPatchesContentFile
        cat oldnetsimPatchesUrlsFile >  /netsim/simdepContents/NetsimPatches_CXP9032769.Urls
        echo "ERROR: Patch is not installed properly. Please install again"
        exit 1
    fi
done

