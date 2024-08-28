#!/bin/bash
#
##############################################################################
#     File Name     : copyDeltaContents.sh
#     Author        : Sneha Srivatsav Arra
#     Description   : Copies Sim Contents to necessary files in /netsim/simdepContents directory
#     Date Created  : 12 April 2018
###############################################################################
#
###################################################################
#Variables
###################################################################
SIMDEP_CONTENTS="/netsim/simdepContents"
simLTE=$1
simWRAN=$2
simCORE=$3
####################################################################
# Copy Delta COntents
####################################################################

cd /netsim/simdepContents
simnetContentFile=$(ls|grep .content | grep 'Simnet\|nssModule\|nssMod')

cat deltaContentUrls.content >> $simnetContentFile

for simLTEName in ${simLTE//:/ }
do
    echo "simLTEName is: $simLTEName"
    if [ ${simLTEName} != "NO_NW_AVAILABLE" ]
    then
        grep "${simLTEName}" deltaContentUrls.content >> Simnet.Urls
    fi
done
for simWRANName in ${simWRAN//:/ }
do
    echo "simWRANName is: $simWRANName"
    if [ ${simWRANName} != "NO_NW_AVAILABLE" ]
    then
        grep "${simWRANName}" deltaContentUrls.content >> Simnet.Urls
    fi
done
for simCOREName in ${simCORE//:/ }
do
    echo "simCOREName is: $simCOREName"
    if [ ${simCOREName} != "NO_NW_AVAILABLE" ]
    then
        grep "${simCOREName}" deltaContentUrls.content >> Simnet.Urls
    fi
done
rm -rf deltaContentUrls.content