#!/bin/sh
## $Id: start_all_simne.sh,v 1.5 2006/08/30 11:50:25 qbejoha Exp $
## This script should be piped to netsim_pipe.
## It will start all simulations listed in a file or, if no file exists,  
## all simulations in the simulations directory EXCEPT the default
## simulation.
##
## The simulation file should be placed in $NETSIMDIR and should have
## one simulation name on each line, optionally followed by a set of
## activites seperated by spaces to be started.
##
## Example $NETSIMDIR/simulations file that will start the simulation
## mySimulation and start activites activity1 and activity2:
##
## mySimulation activity1 activity2
if [ "$NETSIMDIR" = "" ] ; then
    NETSIMDIR=$HOME/netsimdir
fi
export NETSIMDIR

if [ -r $NETSIMDIR/simulations ] ; then
    SIMULATIONS=`cat $NETSIMDIR/simulations`
else
    SIMULATIONS=`ls -1 $NETSIMDIR/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" |grep -v -E '^default$'`
fi
echo "$SIMULATIONS" | while read sim acts
do
    nes=`echo -e ".open $sim\n .show simnes" | $HOME/inst/netsim_shell`
    ipv6Nes=`echo "$nes" | grep "::"| sort | awk -F" " '{print \$1}'`
    ipv6NesArr=(${ipv6Nes//:/})       # Convert String to Array
    ipv4Nes=`echo "$nes" | grep -v "::"|cut -d ' ' -f 1 | tail -n+5 |sed '$d'`
    ipv4NesArr=(${ipv4Nes//:/})       # Convert String to Array
    if [ "${#ipv4NesArr[@]}" -gt "5" ] ; then
        numOfNes=5
    else
        numOfNes=${#ipv4NesArr[@]}
    fi
    nodes=""
    for (( count=0 ; count<=$numOfNes ; count++ )) {
        if [ "$count" -eq "$numOfNes" ] ; then
            simNes=$nodes" "${ipv6NesArr[0]}
            $HOME/inst/netsim_pipe<<EOF
.open $sim
.select $simNes
.start
EOF
        else
            nodes=$nodes" "${ipv4NesArr[count]}
        fi
    }
    for act in $acts
    do
        echo ".setactivity $act"
        echo ".startactivity"
    done
done
