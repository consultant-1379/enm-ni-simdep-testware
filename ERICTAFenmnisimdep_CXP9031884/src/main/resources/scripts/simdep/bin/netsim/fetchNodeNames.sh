#!/bin/sh
###################################################################################
#     File Name    : fetchNodeNames.sh
#     Author       : zhainic
#     Description  : gets the node names present in server
#     Date Created : 22 July 2019
###################################################################################
usage(){
echo "usage: ./fetchNodeNames.sh firstserverName installationType"
echo "example: ./fetchNodeNames.sh ieatnetsimv5109-05 online"
}

if [ $# -ne 2 ]
then
usage
exit 1
fi
######################################################
serverName=$1
install_Type=$2
######################################################

cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar .
 #if [[ $? -ne 0 ]]
 #then
 # echo "ERROR: Downloading .jq  failed."
   #  exit 1
# fi


tar -xvf jq-1.0.1.tar
chmod +x ./jq
HOSTNAME=`hostname`

if [ -e /netsim/netsimdir/networkMap.json ]
then
cat /netsim/netsimdir/networkMap.json | ./jq '.networkMap[].name'| sed 's/\"//g' > $HOSTNAME.txt

   if [[ $serverName == *"netsim"* ]]
   then
/usr/bin/expect<<EOF
        set timeout -1
        spawn scp -o StrictHostKeyChecking=no $HOSTNAME.txt netsim@${serverName}.athtem.eei.ericsson.se:/netsim/
        expect {
                 -re Are {send "yes\r";exp_continue}
         -re assword: {send "netsim\r";exp_continue}
        }
        sleep 2
EOF
   else
/usr/bin/expect<<EOF
        set timeout -1
        spawn scp -o StrictHostKeyChecking=no $HOSTNAME.txt netsim@${serverName}:/netsim/
        expect {
                 -re Are {send "yes\r";exp_continue}
         -re assword: {send "netsim\r";exp_continue}
        }
        sleep 2
EOF
   fi
rm -rf $HOSTNAME.txt
else
echo "ERROR: networkMap.json file doesn't exit"
exit 1
fi
