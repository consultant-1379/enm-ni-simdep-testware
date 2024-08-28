#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [  -f /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar ]
then

cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar . 

else
cp $SCRIPT_DIR/../../../bin/netsim/jq-1.0.1.tar .
fi
tar -xvf jq-1.0.1.tar ; chmod +x ./jq
masterServer=$1;
serverName=$2;
serverType=$3;

simname=`ls -dm /netsim/netsimdir/* | grep RAN | tr -d /netsim/netsimdir/`

map_generator=`/netsim/inst/netsim_pipe<<EOF
.generateNetworkMap
EOF`

echo "$map_generator"
for simulation in $(echo $simname | sed "s/,/ /g")
do
        Nodedetails=`./jq  --raw-output '.networkMap[] | select(.["Simulation"]=="'$simulation'") ' /netsim/netsimdir/networkMap.json `
while [ ! -z "$Nodedetails" ]
do
  Node=`echo $Nodedetails | awk -F"}" '{print $1}'`
  NodeIp=`echo $Node | awk -F'ip": "' '{print $2}'| awk -F'"' '{print $1}'`
  Nodename=`echo $Node | awk -F'name": "' '{print $2}'| awk -F'"' '{print $1}'`
  Nodedetails=`echo $Nodedetails | awk -F"}" '{print $2}'`
  echo `./createXML.sh "$NodeIp" "$Nodename"`
  certsPath='/tmp/RAN-VNF/security/'$Nodename
  rm -rf $certsPath
  mkdir -p $certsPath
  mv "$Nodename.xml" $certsPath
  echo `./CopyCerts.pl "$masterServer" "$serverName" "$serverType" "$Nodename" "$certsPath"`
  echo "INFO: Copying s_cacert"
  cp /netsim/s_cacert-1.0.2.pem .
  echo `./ModifyTLS.pl "$simulation" "$Nodename" "$certsPath"`
done
done

rm -rf jq-1.0.1.tar jq
