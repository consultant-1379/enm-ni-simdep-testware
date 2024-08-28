#!/bin/sh
SIMLIST=`ls /netsim/netsimdir | grep LTE |  grep -E "TDD" |  grep -v "zip" `

SIMS=(${SIMLIST// / })
for SIM in ${SIMS[@]}
#echo -e 'Simulation is $SIM'
do
NODELIST=$(echo -e '.open '$SIM'\n.show simnes' | /netsim/inst/netsim_shell | grep -vE 'OK|NE|>>' | awk '{print $1}')
NODES=(${NODELIST// / })

for NODE in ${NODES[@]}
#echo -e 'Node is $NODE'
do
if [[ $SIM =~ "DG2" ]]
then
echo -e '.open '$SIM'\n.select '$NODE'\ne [csmodb:delete_mo_by_id(null,MOID) || MOID <- csmo:get_mo_ids_by_type(null, "Lrat:EUtranFrequency"), string:chr(csmo:get_mo_name_by_id(null, MOID), 69) =:= 1].' | /netsim/inst/netsim_shell
echo -e '.open '$SIM'\n.select '$NODE'\ne [csmodb:delete_mo_by_id(null,MOID) || MOID <- csmo:get_mo_ids_by_type(null, "Lrat:EUtranFreqRelation"), string:chr(csmo:get_mo_name_by_id(null, MOID), 69) =:= 1].' | /netsim/inst/netsim_shell
else

echo -e '.open '$SIM'\n.select '$NODE'\ne [csmodb:delete_mo_by_id(null,MOID) || MOID <- csmo:get_mo_ids_by_type(null, "EUtranFrequency"), string:chr(csmo:get_mo_name_by_id(null, MOID), 69) =:= 1].' | /netsim/inst/netsim_shell
echo -e '.open '$SIM'\n.select '$NODE'\ne [csmodb:delete_mo_by_id(null,MOID) || MOID <- csmo:get_mo_ids_by_type(null,"EUtranFreqRelation"), string:chr(csmo:get_mo_name_by_id(null, MOID), 69) =:= 1].' | /netsim/inst/netsim_shell
fi
done
done
