#!/bin/sh


sims=`echo -e '.show simulations\n' | /netsim/inst/netsim_shell | grep -vE 'OK|>>|default|zip'`

for simName in ${sims[@]}
do
cat >> startNodesCheck.mml << ABC
.open $simName
.select network
.start -parallel
.stop -parallel
ABC
done

/netsim/inst/netsim_shell < startNodesCheck.mml
rm -rf startNodesCheck.mml
