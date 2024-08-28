#!/bin/sh

usage(){
echo "usage: $0 simname"
echo "example: $0 GSM-FT-MSC-DB-BSP-15cell_BSC_23-Q2_V2x9-GSM11"
}

if [ $# -ne 1 ]
then
usage
exit 1
fi
Simname=$1
fileName=/var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/${Simname}_assignip.mml
cp /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/jq-1.0.1.tar .
tar -xvf jq-1.0.1.tar
chmod 777 ./jq
if [ -e /netsim/netsimdir/networkMap.json ]
then
  NODELIST=`cat /netsim/netsimdir/networkMap.json | ./jq --arg Simname "$Simname" '.networkMap[]|select(.Simulation==$Simname)|.name' |  sed 's/\"//g'`
  IPLIST=`cat /netsim/netsimdir/networkMap.json | ./jq --arg Simname "$Simname" '.networkMap[]|select(.Simulation==$Simname)|.ip' |  sed 's/\"//g'`
else
  echo "ERROR: networkMap.json file doesn't exit"
  exit 1
fi
NODES=(${NODELIST// / })
IPS=(${IPLIST// / })
echo "${NODES[@]}"
echo "${IPS[@]}"
rm -rf ${fileName}
cat >> ${fileName}  << ABC
.open $Simname
ABC
count=0
for node  in ${NODES[@]}  #ip in ${IPS[@]}
do
ip=${IPS[$count]}
cat >> ${fileName} << ABC
.select $node
.stop 
.modifyne set_subaddr $ip subaddr no_value
.set taggedaddr subaddr $ip 1
.set save 
ABC
count=$((count+1))
done
python /var/simnet/enm-ni-simdep/scripts/simdep/bin/netsim/gsm_MSC_assign.py $Simname
#cat $Simname_assign.mml
