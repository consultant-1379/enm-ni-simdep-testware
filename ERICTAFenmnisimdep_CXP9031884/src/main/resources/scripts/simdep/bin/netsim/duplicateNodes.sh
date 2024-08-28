#!/bin/sh
#######################################################
#       File Name   : duplicateNodes.sh
#       Author      : zhainic
#       Description : compares the nodes present in network
#       Date        : 22 July 2019
#       Usage       : ./duplicateNodes.sh
#######################################################

usage(){
echo "usage: $0 installationType"
echo "example: $0 online"
}

if [ $# -ne 1 ]
then
usage
exit 1
fi
######################################################
install_Type=$1
HOSTNAME=`hostname`
######################################################


if [ $HOSTNAME == "netsim" ]
then
        cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar .
        ###if [[ $? -ne 0 ]]
        #then
          # echo "ERROR: Downloading .jq  failed."
           #exit 1
        #fi
     tar -xvf jq-1.0.1.tar
     chmod +x ./jq
     if [ -e /netsim/netsimdir/networkMap.json ]
     then
        cat /netsim/netsimdir/networkMap.json | ./jq '.networkMap[].name'| sed 's/\"//g' > /var/simnet/listOfNodes.txt
     else
        echo "ERROR: networkMap.json file doesn't exit"
     exit 1
     fi
else
     cat /netsim/*.txt > /var/simnet/listOfNodes.txt
     mv /netsim/*.txt /var/simnet/
fi

if [ -s /var/simnet/listOfNodes.txt ]
then
   duplicate=`cat /var/simnet/listOfNodes.txt | sort | uniq -d`
   if [[ -z $duplicate ]]
   then
      echo "*********************No Duplicate Nodes in Network*********************"
   else
      echo "ERROR: There are duplicate nodes in Network"
      echo -e "duplicated node names are \n$duplicate"
      exit 1
   fi
else
   echo "ERROR: ListofNodes File doesn't exit or size of file is zero"
   exit 1
fi
