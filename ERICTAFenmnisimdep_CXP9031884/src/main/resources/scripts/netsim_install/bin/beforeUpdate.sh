#!/bin/sh

count=0
while : 
do
timeout -k 5m 6m sh /var/simnet/enm-ni-simdep/scripts/netsim_install/bin/stopNodes.sh

count=$(expr "$count" + 1)
startNodesCount=`su netsim -c "echo -e '.show numstartednes\n' | /netsim/inst/netsim_shell -q"`
echo "StartedNodesCount=$startNodesCount"
if [[ $startNodesCount == 0 ]]
then
echo "INFO: All nodes are stopped"
exit 0
fi
if [[ $count == 10 ]]
then
echo "ERROR: Unable to stop all the nodes even with 10 tries"
exit 1
fi
done
