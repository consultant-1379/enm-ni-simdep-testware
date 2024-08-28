#!/bin/sh

cp /var/tmp/jq-1.0.1.tar . ; tar -xvf jq-1.0.1.tar ; chmod +x ./jq

hostname=`hostname -i`
cat $1 | awk '{print $1}' > temp
rm -rf /var/tmp/$hostname
touch /var/tmp/$hostname

for node in $(cat temp)
do
  Simulation_name=`cat /netsim/netsimdir/networkMap.json | ./jq '.networkMap[] |select(.["name"]=="'"$node"'")|.Simulation' | sed 's/\"//g'`
    if [[ ! -z $Simulation_name ]]
    then
        type=`cat $1 | grep $node | awk '{print $2}'`
        echo "$hostname $Simulation_name $node $type" >> /var/tmp/$hostname
    fi
done
